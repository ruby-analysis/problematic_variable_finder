require 'problematic_variable_finder/main_finder'
require 'problematic_variable_finder/problem'

module ProblematicVariableFinder
  class ProblemFinder
    include FsCaching

    def find_problems_in_directory(path, remove_paths=[])
      key = [path, remove_paths].inspect

      files = Dir.glob("#{path}/**/*.rb")

      files.reject! do |f|
        filename = f
        filename = remove_paths.each do |path|
          filename = filename.gsub(path, '')
        end

        %w(
            /spec/
            /.bundle/
            /.gems/
            /.git/
            /.rbenv/
            /bin/
            /features/
            /test/
            /vendor/
            _spec.rb
            _test.rb
        ).any? do |s|
          filename.include?(s)
        end
      end

      files.flat_map do |f|
        _, path, problems = find_file_problems(f, remove_paths)
        problems.map do |problem|
          Problem.new(
            type: problem[:type],
            filename: path,
            line_number: problem[:line_number],
            code: problem[:name].to_s
          )
        end
      end
    end

    def find_file_problems(f, remove_paths)
      full_path = File.expand_path f
      friendly_path = full_path
      remove_paths.each do |p|
        friendly_path = friendly_path.gsub(p, '')
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
