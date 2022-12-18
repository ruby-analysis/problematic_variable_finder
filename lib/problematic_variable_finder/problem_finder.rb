require 'problematic_variable_finder/main_finder'

module ProblematicVariableFinder
  class ProblemFinder
    include FsCaching

    def find_problems_in_directory(path, remove_paths=[])
      key = [path, remove_paths].inspect

      cache(key) do
        files = Dir.glob("#{path}/**/*.rb")
        files.reject! do |f| 
          f.include?('/spec/') || 
            f.include?('/.bundle/') || 
            f.include?('/.gem/') ||
            f.include?('/.gems/') ||
            f.include?('/.git/') ||
            f.include?('/.rbenv/') ||
            f.include?('/.rvm/') ||
            f.include?('/bin/') ||
            f.include?('/features/') || 
            f.include?('/test/') ||
            f.include?('/vendor/') ||
            f.include?('_spec.rb') ||
            f.include?('_test.rb') 
        end

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
                   MainFinder.call(ProblematicVariableFinder.read_file(full_path))
                 rescue => e
                   puts "Error parsing #{f} #{e}"
                   []
                 end

      [full_path, friendly_path, problems]
    end
  end
end
