module ProblematicVariableFinder
  module Formatters
    class DisplayCliProblem
      attr_reader :gem_name, :full_path, :path, :problem

      def initialize(gem_name, full_path, path, problem)
        @gem_name = gem_name
        @full_path = full_path
        @path = path
        @problem = problem
      end

      def call
        print_problem_header

        puts code_with_line_numbers
      end

      def code_with_line_numbers
        range_line_numbers.zip(code_lines).map do |number, line| 
          "#{number}: #{line}"
        end.join("\n")
      end

      def range_line_numbers
        range.map{|n| n.to_s.rjust(3, ' ')}
      end

      def code_lines
        code = file_contents.split("\n")[range].join("\n")
        code = code.gsub(snippet, "\e[31m#{snippet}\e[0m")
        code.split("\n")
      end

      def range 
        [line_number - 2, 0].max..line_number + 2
      end

      def line_number
        problem[:line_number]
      end

      def name
        problem[:name]
      end

      def file_contents
        @file_contents ||= ::ProblematicVariableFinder.read_file(full_path)
      end

      def snippet
        case name
        when String
          name
        when Symbol
          name.to_s
        when Parser::AST::Node
          file_contents[name.loc.expression.begin_pos..name.loc.expression.end_pos]
        end
      end

      def print_problem_header
        puts '-----------------'
        puts "#{gem_name}"
        puts "#{path}:#{line_number}"
        puts "#{problem[:type]}: #{problem[:name]}"
        puts
      end
    end
  end
end
