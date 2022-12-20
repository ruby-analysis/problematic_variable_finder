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
      gems.flat_map do |gem|
        next if ignore_gem?(gem.name)
        next if exclude_because_of_only_list?(gem.name)

        key = "#{gem.name_and_version}-cache-bust-2"

        gem_problems = cache(key) do
          find_gem_problems(gem)
        end

        objectify(gem.name, gem.version, gem_problems)
      end.compact
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
      @outdated_gems ||= outdated.map { |o| o.gsub(/\s+\*\s+/, '').split(" ").first }
    end

    def all_gems
      `bundle list --only-group default production | grep '*' | awk '{print $2}'`
        .split("\n").map(&:chomp)
    end

    def outdated
      @outdated ||= cache("BUNDLE_OUT_OF_DATE_INFO_#{gemfile_lock_sha}") do
        `bundle outdated --parseable`.split("\n").map do |s|
          s.split(" ").first&.strip
        end.compact
      end
    end

    def gemfile_lock_sha
      return '' if ProblematicVariableFinder.options.force_cache

      Digest::SHA1.hexdigest(ProblematicVariableFinder.read_file('Gemfile.lock')) + "v3"
    end

    def find_gem_problems(gem)
      directory = "#{gem_path}/#{gem.name_and_version}/"
      folder = gem_path + '/' + gem.name_and_version + '/'
      lib_folder = folder + 'lib' + '/' + gem.name + '/'

      problem_finder.find_problems_in_directory(directory, [folder, lib_folder])
    end

    def problem_finder
      @problem_finder ||= ProblemFinder.new
    end
  end
end
