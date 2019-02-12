require 'parser/current'
require 'active_support/all'
require 'rspec'
require 'byebug'

module Parsing
  def parser
    @parser ||= Parser::CurrentRuby
  end

  def parse(c)
    return OpenStruct.new(children: []) if c.blank?
    parser.parse(c)
  end

  def find(type)
    to_a(sexp, type)
  end

  def to_a(sexp, filter=nil)
    return [] unless sexp.respond_to?(:children)

    sexp.children.map(&children_of(filter)).flatten.select do |a|
      a.is_a?(SexpWrapper)
    end
  end

  def children_of(filter=nil)
    lambda do |s|
      if s.respond_to?(:children)
        children = to_a(s, filter).reject(&:blank?)

        if filter && s.type == filter
          SexpWrapper.new(s, children)
        else
          children
        end
      else
        s
      end
    end
  end
end


class ProblematicVariableFinder
  include Parsing

  def self.call(code)
    new(code: code).call
  end

  def initialize(code:nil, sexp:nil)
    @code = code
    @sexp = sexp || (parse(code) if code)
  end

  def call
    sort(global_variables + class_variables + class_instance_variables)
  end

  attr_reader :code

  # gvasgn gvar
  def global_variables
    assignments = find(:gvasgn).map do |s|
      {type: :global_variable, line_number: s.line, name: s.sexp.children.first}
    end

    variables = find(:gvar).map do |s|
      {type: :global_variable, line_number: s.line, name: s.sexp.children.last}
    end

    sort(assignments + variables)
  end

  # cvar cvasgn
  def class_variables
    cvars = find(:cvar).map do |s|
      {type: :class_variable, line_number: s.line, name: s.sexp.children.first}
    end

    cvasgns = find(:cvasgn).map do |s|
      {type: :class_variable, line_number: s.line, name: s.sexp.children.first}
    end

    sort(cvars + cvasgns)
  end

  # ivar ivasgn
  def class_instance_variables
    scopes = find(:sclass) + find(:defs)
    civs = scopes.map{|s| s.find(:ivar)}.flatten.map do |s|
      {type: :class_instance_variable, line_number: s.line, name: s.sexp.children.first}
    end

    cvasns = scopes.map{|s| s.find(:ivasgn)}.flatten.map do |s|
      {type: :class_instance_variable, line_number: s.line, name: s.sexp.children.first}
    end

    sort(civs + cvasns)
  end

  def sort(results)
    results.sort{|a, b| a[:line_number] <=> b[:line_number]}
  end


  def sexp
    @sexp ||= parse(code)
  end

  def type
    sexp.type
  end
end

class SexpWrapper
  include Parsing

  def initialize(sexp, children)
    @sexp = sexp
    @children = children
  end

  def line
    sexp.loc.line
  end

  attr_reader :sexp, :children
end

RSpec.describe ProblematicVariableFinder do
  let(:code) do
    <<-RUBY
      module Top
        module Thing
          class Something
            def self.egg
              @a_thing
            end

            class << self
              def thing
                @another_thing
                @this_one_too = 'this'
              end
            end

            def not_a_thing
              @not_a_thing
              @this_other_one_too = 'that'
            end

            def self.thing_2
              @@a_thing_2
              @this_other_one_too = 'hey'
            end

            class << self
              def another_thing_2
                @@another_thing_2 = 'yoho'
                @this_other_one_too ||= 'boom'
                $some_global = 'evil'
              end
            end
          end
        end
        $global = 'bad'
        $this_global
      end
    RUBY
  end

  describe "#class_instance_variables" do
    it do
      result = described_class.new(code: code).class_instance_variables
      expect(result.length).to eq 5

      expect(result).to eq [
        {:type => :class_instance_variable, :line_number=>5,  :name=>:@a_thing},
        {:type => :class_instance_variable, :line_number=>10, :name=>:@another_thing},
        {:type => :class_instance_variable, :line_number=>11, :name=>:@this_one_too},
        {:type => :class_instance_variable, :line_number=>22, :name=>:@this_other_one_too},
        {:type => :class_instance_variable, :line_number=>28, :name=>:@this_other_one_too},
      ]
    end
  end

  describe "#global_variables" do
    it do
      result = described_class.new(code: code).global_variables
      expect(result).to eq [
        {type: :global_variable, line_number: 29, name: :"$some_global"},
        {type: :global_variable, line_number: 34, name: :"$global"},
        {type: :global_variable, line_number: 35, name: :$this_global, }
      ]
    end
  end

  describe "#class_variables" do
    it do
      result = described_class.new(code: code).class_variables
      expect(result).to eq [
        {:line_number=>21, :name=>:@@a_thing_2, :type=>:class_variable},
        {:line_number=>27, :name=>:@@another_thing_2, :type=>:class_variable}
      ]
      expect(result.length).to eq 2
    end
  end
end


if File.basename($0) == __FILE__
  ARGV.each do |arg|
    if File.exist?(arg)
      files = if File.directory?(arg)
                Dir.glob("#{arg}/**/*.rb")
              else
                Array(arg)
              end

      files.each do |f|
        file = File.expand_path f
        begin
          problems = ProblematicVariableFinder.call(File.read file)

          problems.map{|p|
            puts "#{file}:#{p[:line_number]} #{p[:type]}: #{p[:name]}"
          }
        rescue => e
          puts "Error parsing #{f} #{e}"
        end
      end
    end
  end
end
