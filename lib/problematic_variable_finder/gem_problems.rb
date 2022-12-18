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
      problems = {}

      gems.each do |name, version|
        next if ignore_gem?(name)
        next if exclude_because_of_only_list?(name)

        key = "#{name}-#{version}"

        gem_problems = cache(key) do
          find_gem_problems(name, version)
        end

        gem_problems = objectify(gem_problems)

        problems[key] = gem_problems if gem_problems.any?
      end

      puts problems

      problems
    end

    def objectify(gem_problems)
      gem_problems.flat_map do |filename, file_problems|
        file_problems.map do |problem|
          Problem.new(
            gem_name: name,
            gem_version: version,
            type: problem[:type],
            filename: filename,
            line_number: problem[:line_number],
            code: problem[:name].to_s,
            out_of_date: outdated_gems.include?(name)
          )
        end
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
      @outdated_gems ||= outdated.map{|o| o.gsub(/\s+\*\s+/, '').split(" ").first }
    end

    def outdated
      @outdated ||= cache('BUNDLE_OUT_OF_DATE_INFO') do
        `bundle outdated`.split("\n").grep(/ \*/).reject do |s|
          s['development'] ||
            s['test']
        end
      end
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
