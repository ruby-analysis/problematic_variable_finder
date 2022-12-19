require 'problematic_variable_finder/formatters/display_cli_problem'

module ProblematicVariableFinder
  module Formatters
    class CliFormatter
      attr_reader :problems

      def initialize(problems)
        @problems = problems
      end 

      def call
        problems.each do |problem|
          DisplayCliProblem.new(problem).call
        end
      end
    end
  end
end
