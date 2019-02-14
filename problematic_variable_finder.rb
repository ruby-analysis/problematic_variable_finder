require 'parser/current'
require 'active_support/all'
require 'rspec'
require 'byebug'
require 'pstore'

module FsCaching
  def store
    @store ||= PStore.new(".gem_problems.pstore")
  end

  def cache(key)
    store.transaction do
      store[key] ||= yield
    end
  end
end

class GemFinder
  include FsCaching

  def call
    cache 'BUNDLE_INSTALL' do
      `bundle install --with=production --without="development test"`

      gems = `bundle list | grep '*'`.split("\n").map{|s| s.gsub(/ *\* /, "")}
      gems = gems.map{|g| g.split("(")}.map{|name, version| [name.strip, version.gsub(")", '').strip]}
      byebug
      first = `bundle show #{gems.first.first}`
      gem_path = first.gsub(gems.first.join('-'), '').strip.gsub(%r{/$}, "")

      [gem_path,  gems]
    end
  end
end


module Parsing
  def parser
    @parser ||= Parser::CurrentRuby
  end

  def parse(c)
    return OpenStruct.new(children: []) if c.blank?
    parser.parse(c)
  end

  def find(*types)
    Array(types).map do |type|
      to_a(sexp, type)
    end.flatten
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

  attr_reader :code

  def initialize(code:nil, sexp:nil)
    @code = code
    @sexp = sexp || (parse(code) if code)
  end

  def call
    sort(global_variables + class_variables + class_instance_variables + class_accessors)
  end

  def global_variables
    variables([:gvar, :gvasgn], :global_variable)
  end

  def class_variables
    variables([:cvar, :cvasgn], :class_variable)
  end

  def class_instance_variables
    result = find(:sclass, :defs).map{|s| s.find(:ivar) + s.find(:ivasgn)}.flatten.map do |s|
      format(s, :class_instance_variable)
    end

    sort result
  end

  def class_accessors
    sort eigen_class_accessors + cattr_accessors
  end

  def eigen_class_accessors
    result = find(:sclass).map do |s|
      s.find(:send).select{|s2| [:attr_accessor, :attr_writer, :attr_reader].include? s2.sexp.children[1] }
    end.reject(&:blank?)

    result.flatten.map do |r|
      name = r.last_child.children.first
      format(r, :class_accessor, name)
    end
  end

  def cattr_accessors
    result = find(:send).select do |s2|
      [
        :cattr_accessor, :cattr_writer, :cattr_reader,
        :mattr_accessor, :mattr_writer, :mattr_reader
      ].include? s2.sexp.children[1]
    end

    result.flatten.map do |r|
      name = r.last_child.children.first
      format(r, :class_accessor, name)
    end
  end

  private

  def variables(nodes, type)
    result = find(*nodes).map do |s|
      format(s, type)
    end

    sort result
  end

  def sort(results)
    results.sort{|a, b| a[:line_number] <=> b[:line_number]}
  end

  def format(s, type, name=nil)
    name ||= s.first_child
    {type: type, line_number: s.line, name: name}
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

  def first_child
    sexp.children.first
  end

  def last_child
    sexp.children.last
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
        class << self
          define_method :another_thing do
            @a = 2
          end

          attr_accessor :this
          attr_writer :that
          attr_reader :these
        end

        cattr_accessor :a
        cattr_writer :b
        cattr_reader :c
        mattr_accessor :d
        mattr_writer :e
        mattr_reader :f

        # not problem causing
        thread_cattr_accessor :g
        thread_cattr_writer :h
        thread_cattr_reader :i
        thread_mattr_accessor :j
        thread_mattr_writer :k
        thread_mattr_reader :l
      end
    RUBY
  end

  describe "#class_accessors" do
    it do
      result = described_class.new(code: code).class_accessors
      expect(result.length).to eq 9

      expect(result).to eq [
        {:type => :class_accessor, :line_number =>41, :name=>:this},
        {:type => :class_accessor, :line_number =>42, :name=>:that},
        {:type => :class_accessor, :line_number =>43, :name=>:these},

        {:type => :class_accessor, :line_number =>46, :name=>:a},
        {:type => :class_accessor, :line_number =>47, :name=>:b},
        {:type => :class_accessor, :line_number =>48, :name=>:c},

        {:type => :class_accessor, :line_number =>49, :name=>:d},
        {:type => :class_accessor, :line_number =>50, :name=>:e},
        {:type => :class_accessor, :line_number =>51, :name=>:f},
      ]
    end
  end

  describe "#class_instance_variables" do
    it do
      result = described_class.new(code: code).class_instance_variables
      expect(result.length).to eq 6

      expect(result).to eq [
        {:type => :class_instance_variable, :line_number=>5,  :name=>:@a_thing},
        {:type => :class_instance_variable, :line_number=>10, :name=>:@another_thing},
        {:type => :class_instance_variable, :line_number=>11, :name=>:@this_one_too},
        {:type => :class_instance_variable, :line_number=>22, :name=>:@this_other_one_too},
        {:type => :class_instance_variable, :line_number=>28, :name=>:@this_other_one_too},
        {:type => :class_instance_variable, :line_number=>38, :name=>:@a},
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
  gem_path, gems = GemFinder.new.call
end


class ProblemFinder
  include FsCaching

  def initialize(gem_path, gems)
    @gem_path, @gems = gem_path, gems
  end

  attr_reader :gem_path, :gems

  def call
    problems = {}
    outdated = cache 'BUNDLE_OUT_OF_DATEx_INFO' do
      `bundle outdated`.split("\n").grep(/ \*/).reject do |s|
        s['in groups "development, test"'] ||
        s['in groups "development"'] ||
        s['in groups "test"'] ||
        s['in groups "test, development"']
      end
    end

    names = outdated.map{|o| o.gsub(/\s+\*\s+/, '').split(" ").first }

    gems.each do |name, version|
      key = "#{name}-#{version}"

      gem_problems = cache(key) do
        find_gem_problems(name, version)
      end
      gem_is_out_of_date = names.include?(name)

      problems[key] = [gem_problems, gem_is_out_of_date] if gem_problems.any?
    end

    [problems, outdated]
  end

  def find_gem_problems(name, version)
    directory = "#{gem_path}/#{name}-#{version}/"
    folder = gem_path + '/' + [name, version].join('-') + '/'
    lib_folder = folder + 'lib' + '/' + name + '/'

    find_problems_in_directory(director, [folder, lib_folder])
  end

  def find_problems_in_directory(path, remove_paths=[])
    key = [path, remove_paths].inspect
    cache(key) do
      files = Dir.glob("#{path}/**/*.rb")

      directory_problems = {}

      files.each do |f|
        full_path, path, problems = find_file_problems(f, remove_paths)
        directory_problems[path]  = [full_path, problems] if problems.any?
      end

      directory_problems
    end
  end

  def find_file_problems(f, remove_paths)
    full_path = File.expand_path f
    friendly_path = full_path
    remove_paths.each do |p|
      friendly_path = f.gsub(p, '')
    end

    problems = begin
      ProblematicVariableFinder.call(File.read full_path)
    rescue => e
      puts "Error parsing #{f} #{e}"
      []
    end

    [full_path, friendly_path, problems]
  end
end

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-g", "--gems rails,activerecord", Array, "List of gems") do |g|
    options[:gems] = g
  end
end.parse!

VERBOSE= options[:verbose]
GEMS= options[:gems]

def display_problems(problems)
  problems.each do |path, (full_path, file_problems)|
    file_problems.each do |problem|
      display_problem(full_path, path, problem)
    end
  end
end

def display_problem(full_path, path, problem)
  formatted_file_and_line = [full_path, problem[:line_number]].join(':').ljust(150)
  puts "        #{problem[:type].to_s.ljust(30, ' ')} #{path}:#{problem[:line_number]} : #{problem[:name]} #{formatted_file_and_line}"
end

if gem_path
  app_problems = ProblemFinder.new(gem_path, gems).find_problems_in_directory("app")
  lib_problems = ProblemFinder.new(gem_path, gems).find_problems_in_directory("lib")

  display_problems(app_problems.merge lib_problems)

  gem_problems, out_of_date = ProblemFinder.new(gem_path, gems).call

  gem_problems.each do |gem_name, (problems, out_of_date)|
    *name, version = gem_name.split("-")
    name = name.join("-")
    if Array(GEMS).any?
      next unless GEMS.include?(name)
    end
    puts '-----------------'
    puts "#{gem_name} #{out_of_date ? '(out of date)' : ''} #{problems.flatten.length} possible issues"

    next unless VERBOSE

    display_problems(problems)
  end

  puts "Out of date gems:"
  puts out_of_date
end
