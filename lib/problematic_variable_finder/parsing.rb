module ProblematicVariableFinder
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
        child = sexp.children.first
        case child
        when Symbol
          child
        else
          self.class.new(child, to_a(child))
        end
      end

      def last_child
        child = sexp.children.last
        case child
        when Symbol
          child
        else
          self.class.new(child, to_a(child))
        end
      end

      attr_reader :sexp, :children
      delegate_missing_to :sexp
    end
  end
end
