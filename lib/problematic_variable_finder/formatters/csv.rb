require 'problematic_variable_finder/formatters/display_cli_problem'

module ProblematicVariableFinder
  module Formatters
    class Csv < CliFormatter
      private

      def display_problem(full_path, path, problem)
        DisplayCsvProblem.new(gem_name, full_path, path, problem).call
      end
    end
  end
end
