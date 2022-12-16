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
        key = "#{name}-#{version}"

        gem_problems = cache(key) do
          find_gem_problems(name, version)
        end
        gem_is_out_of_date = outdated_gems.include?(name)

        problems[key] = [gem_problems, gem_is_out_of_date] if gem_problems.any?
      end

      problems
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

      find_problems_in_directory(directory, [folder, lib_folder])
    end
  end
end
