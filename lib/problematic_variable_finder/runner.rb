require 'optparse'
require 'parser/current'
require 'active_support/all'
require 'pstore'
require 'byebug'

require 'problematic_variable_finder/gem_finder'
require 'problematic_variable_finder/gem_problems'
require 'problematic_variable_finder/problem_finder'
require 'problematic_variable_finder/formatters/cli_formatter'

module ProblematicVariableFinder
  class Runner
    def self.call
      new.call
    end

    def call
      display_problems('main app problems', main_problems)
      display_gem_problems

      if gem_problems.outdated_gems.any?
        puts "Out of date gems:"
        puts gem_problems.outdated_gems
      else
        puts "No out of date gems"
      end
    end

    def display_gem_problems
      each_gem_problem do |gem_name, problems, out_of_date|
        if options[:verbose] 
          display_problems(gem_name, problems)
        else
          puts '-----------------'
          puts "#{gem_name} #{out_of_date ? '(out of date)' : ''} #{problems.flatten.length} possible issues"
        end
      end
    end

    def display_problems(gem_name, problems)
      Formatters::CliFormatter.new(gem_name, problems).call
    end

    def each_gem_problem
      gem_problems.problems.each do |gem_name, (problems, out_of_date)|
        yield gem_name, problems, out_of_date
      end
    end

    def main_problems
      app_problems.merge(lib_problems)
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
      @gem_problems ||= GemProblems.new(gem_path, gems, options)
    end

    def problem_finder
      @problem_finder ||= ProblemFinder.new
    end

    def options
      @options ||= parse_options
    end

    def parse_options
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          options[:verbose] = v
        end

        opts.on("-d", "--directory", "Directory to find app in") do |d|
          options[:directory] = d
        end

        opts.on("-i", "--ignore rails,activerecord", Array, "Ignore gems") do |i|
          options[:ignore] = i
        end

        opts.on("-g", "--gems rails,activerecord", Array, "List of gems") do |g|
          options[:gems] = g
        end
      end.parse!

      options
    end
  end
end
