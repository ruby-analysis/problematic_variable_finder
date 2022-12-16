require 'problematic_variable_finder/parsing'

module ProblematicVariableFinder
  class MainFinder
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
end
