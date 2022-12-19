require 'problematic_variable_finder/formatters/cli_formatter'
require 'problematic_variable_finder/formatters/display_csv_problem'
require 'csv'

module ProblematicVariableFinder
  module Formatters
    class Csv < CliFormatter
      def call
        CSV.open(csv_filename, "#{write_mode}b") do |csv|
          unless exists?
            csv << [
              'github_link',
              'gem_name',
              'gem_version',
              'out_of_date',
              'location',
              'type',
              'code'
            ]
          end

          problems.compact.each do |problem|
            csv << display_problem(problem)
          end

          csv
        end
      end

      private

      def write_mode
        exists? ? "a" : "w"
      end

      def exists?
        return @exists if defined?(@exists)

        @exists = File.exist?(csv_filename)
      end

      def csv_filename
        "problematic_variables.csv"
      end

      def display_problem(problem)
        DisplayCsvProblem.new(problem).call
      end
    end
  end
end
