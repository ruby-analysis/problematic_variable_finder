module ProblematicVariableFinder
  module Formatters
    class DisplayCsvProblem < DisplayCliProblem
      def initialize(problem)
        @problem = problem
      end

      def call
        [
          problem.github_link,
          problem.gem_name,
          problem.gem_version,
          problem.out_of_date,
          "#{problem.path}:#{problem.line_number}",
          problem.type,
          problem.code
        ]
      end
    end
  end
end
