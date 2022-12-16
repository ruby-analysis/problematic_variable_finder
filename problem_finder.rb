require_relative './problematic_variable_finder'

class ProblemFinder
  include FsCaching

  def initialize(gem_path, gems)
    @gem_path, @gems = gem_path, gems
  end

  attr_reader :gem_path, :gems

  def call
    problems = {}

    outdated = cache('BUNDLE_OUT_OF_DATE_INFO') do
      `bundle outdated`.split("\n").grep(/ \*/).reject do |s|
        s['development'] ||
        s['test']
      end
    end

    names = outdated.map{|o| o.gsub(/\s+\*\s+/, '').split(" ").first }

    gems.each do |name, version|
      key = "#{name}-#{version}"

      gem_problems = cache(key) do
        find_gem_problems(name, version)
      end
      gem_is_out_of_date = names.include?(name)

      problems[key] = [gem_problems, gem_is_out_of_date] if gem_problems.any?
    end

    [problems, outdated]
  end

  def find_gem_problems(name, version)
    directory = "#{gem_path}/#{name}-#{version}/"
    folder = gem_path + '/' + [name, version].join('-') + '/'
    lib_folder = folder + 'lib' + '/' + name + '/'

    find_problems_in_directory(directory, [folder, lib_folder])
  end

  def find_problems_in_directory(path, remove_paths=[])
    key = [path, remove_paths].inspect

    cache(key) do
      files = Dir.glob("#{path}/**/*.rb")

      directory_problems = {}

      files.each do |f|
        full_path, path, problems = find_file_problems(f, remove_paths)
        directory_problems[path]  = [full_path, problems] if problems.any?
      end

      directory_problems
    end
  end

  def find_file_problems(f, remove_paths)
    full_path = File.expand_path f
    friendly_path = full_path
    remove_paths.each do |p|
      friendly_path = f.gsub(p, '')
    end

    problems = begin
      ProblematicVariableFinder.call(File.read full_path)
    rescue => e
      puts "Error parsing #{f} #{e}"
      []
    end

    [full_path, friendly_path, problems]
  end
end

