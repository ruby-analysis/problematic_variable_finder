require 'problematic_variable_finder/formatters/display_cli_problem'

module ProblematicVariableFinder
  module Formatters
    class CliFormatter
      attr_reader :gem_name, :problems

      def initialize(gem_name, problems)
        @gem_name = gem_name
        @problems = problems
      end 

      def call
        problems.each do |path, (full_path, file_problems)|
          puts

          file_problems.each do |problem|
            display_problem(full_path, path, problem)
          end
        end
      end

      private

      def display_problem(full_path, path, problem)
        DisplayCliProblem.new(gem_name, full_path, path, problem).call
      end
    end
  end
end
