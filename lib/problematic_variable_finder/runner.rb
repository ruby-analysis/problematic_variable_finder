require 'optparse'
require 'parser/current'
require 'active_support/all'
require 'pstore'
require 'byebug'

require 'problematic_variable_finder/gem_finder'
require 'problematic_variable_finder/gem_problems'
require 'problematic_variable_finder/problem_finder'
require 'problematic_variable_finder/formatters/cli_formatter'
require 'problematic_variable_finder/formatters/csv'
require 'problematic_variable_finder/fs_caching'

module ProblematicVariableFinder
  class Runner
    include FsCaching
    def self.call
      new.call
    end

    def call
      display_problems(main_problems)
      display_gem_problems

      if gem_problems.outdated_gems.any?
        puts "Out of date gems:"
        puts gem_problems.outdated_gems
      else
        puts "No out of date gems"
      end
    end

    def display_gem_problems
      if options[:verbose]
        display_problems(gem_problems.problems)
      else
        puts '-----------------'
        puts "#{gem_name} #{out_of_date ? '(out of date)' : ''} #{problems.flatten.length} possible issues"
      end
    end

    def display_problems(problems)
      klass = case options[:format]
              when :csv
                Formatters::Csv
              else
                Formatters::CliFormatter
              end

      klass.new(problems).call
    end

    def main_problems
      cache("main_problems_#{sha_of_all_app_files}") do
        app_problems + lib_problems
      end
    end

    def sha_of_all_app_files
      app = Dir["app/**/*.rb"]
      lib = Dir["lib/**/*.rb"]
      contents = (app + lib).map { |f| (ProblematicVariableFinder.read_file(f)) }.join
      Digest::SHA1.hexdigest(contents)
    end

    def app_problems
      problem_finder.find_problems_in_directory("app")
    end

    def lib_problems
      problem_finder.find_problems_in_directory("lib")
    end

    def gem_finder
      @gem_finder ||= GemFinder.new.call
    end

    def gem_path
      @gem_path ||= gem_finder.first
    end

    def gems
      @gems ||= gem_finder.last
    end

    def gem_problems
      @gem_problems ||= GemProblems.new(gem_path, gems)
    end

    def problem_finder
      @problem_finder ||= ProblemFinder.new
    end

    delegate :options, to: ProblematicVariableFinder
  end
end
