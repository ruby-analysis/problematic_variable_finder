module ProblematicVariableFinder
  module Formatters
    class DisplayCsvProblem < DisplayCliProblem
      def call
        [gem_name, "#{path}:#{line_number}", problem[:type],  problem[:name].to_s]
      end
    end
  end
end
