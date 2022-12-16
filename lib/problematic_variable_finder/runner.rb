require 'optparse'
require 'parser/current'
require 'active_support/all'
require 'pstore'
require 'byebug'

require 'problematic_variable_finder/gem_finder'
require 'problematic_variable_finder/gem_problems'
require 'problematic_variable_finder/problem_finder'

module ProblematicVariableFinder
  class Runner
    def self.call
      new.call
    end

    def call
      #display_problems('main app problems', main_problems)
      display_gem_problems

      puts "Out of date gems:"
      puts gem_problems.outdated_gems
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

    def each_gem_problem
      gem_problems.problems.each do |gem_name, (problems, out_of_date)|
        *name, _version = gem_name.split("-")
        name = name.join("-")
        next if Array(options[:ignore]).include?(name)

        if Array(options[:gems]).any?
          next unless options[:gems].include?(name)
        end

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
      @gem_problems ||= GemProblems.new(gem_path, gems)
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

    def display_problems(gem_name, problems)
      problems.each do |path, (full_path, file_problems)|
        puts

        file_problems.each do |problem|
          puts
          display_problem(gem_name, full_path, path, problem)
        end
      end
    end

    def display_problem(gem_name, full_path, path, problem)
      line_number = problem[:line_number]
      puts '-----------------'
      puts "#{gem_name}"
      puts "#{path}:#{line_number}"
      puts
      puts problem[:type]

      range = [line_number - 2, 0].max..line_number + 2
      code = File.read(full_path).split("\n")[range].join("\n")

      range_line_numbers = range.map{|n| n.to_s.rjust(3, ' ')}
      # display code with line numbers
      puts range_line_numbers.zip(code.split("\n")).map{|n, c| "#{n} #{c}"}.join("\n")
    end
  end
end
