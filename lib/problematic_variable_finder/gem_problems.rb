require 'problematic_variable_finder/problem'

module ProblematicVariableFinder
  class GemProblems
    include FsCaching

    def initialize(gem_path, gems)
      @gem_path, @gems = gem_path, gems
    end

    attr_reader :gem_path, :gems

    def problems
      @problems ||= determine_problems
    end

    def determine_problems
      gems.flat_map do |name, version|
        next if ignore_gem?(name)
        next if exclude_because_of_only_list?(name)

        key = "#{name}-#{version}-cache-bust-1"

        gem_problems = cache(key) do
          find_gem_problems(name, version)
        end

        objectify(name, version, gem_problems)
      end
    end

    def objectify(name, version, gem_problems)
      gem_problems.map do |problem|
        problem.gem_name = name
        problem.gem_version = version
        problem.out_of_date = outdated_gems.include?(name)
        problem
      end
    end

    def exclude_because_of_only_list?(name)
      return false unless options[:gems]

      !in_only_gem_list?(name)
    end

    def in_only_gem_list?(name)
      Array(options[:gems]).include?(name)
    end

    def ignore_gem?(name) 
      return true if ignore_list.include?(name)
      options[:ignore] && Array(options[:ignore]).include?(name)
    end

    delegate :options, to: ProblematicVariableFinder

    def ignore_list
      @ignore_list ||= ProblematicVariableFinder.read_file(File.expand_path('DEFAULT_IGNORED_GEMS', __dir__)).split("\n").map(&:strip)
    end

    def outdated_gems
      byebug
      @outdated_gems ||= outdated.map{|o| o.gsub(/\s+\*\s+/, '').split(" ").first }
    end

    def outdated
      @outdated ||= cache("BUNDLE_OUT_OF_DATE_INFO_#{gemfile_lock_sha}") do
        `bundle outdated --group default --group production`.split("\n").map do |s|
          s.split(" ").map(&:strip).first
        end
      end
    end

    def gemfile_lock_sha
      Digest::SHA1.hexdigest(ProblematicVariableFinder.read_file('Gemfile.lock'))
    end

    def find_gem_problems(name, version)
      directory = "#{gem_path}/#{name}-#{version}/"
      folder = gem_path + '/' + [name, version].join('-') + '/'
      lib_folder = folder + 'lib' + '/' + name + '/'

      problem_finder.find_problems_in_directory(directory, [folder, lib_folder])
    end

    def problem_finder
      @problem_finder ||= ProblemFinder.new
    end
  end
end
