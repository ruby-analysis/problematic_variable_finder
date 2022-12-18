require 'problematic_variable_finder/formatters/cli_formatter'
require 'problematic_variable_finder/formatters/display_csv_problem'
require 'csv'

module ProblematicVariableFinder
  module Formatters
    class Csv < CliFormatter
      def call
        write_mode = File.exist?(csv_filename) ? "a" : "w"

        CSV.open(csv_filename, "#{write_mode}b") do |csv|
          csv << [
            'github_link',
            'gem_name',
            'gem_version',
            'location',
            'type',
            'code'
          ]

          problems.each do |gem_with_version, gem_problems|
            puts

            gem_problems.each do |problem|
              csv << display_problem(problem)
            end
          end

          csv
        end
      end


      private

      def csv_filename
        "problematic_variables.csv"
      end

      def display_problem(problem)
        DisplayCsvProblem.new(problem).call
      end
    end
  end
end
