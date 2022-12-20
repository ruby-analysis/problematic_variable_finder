require 'problematic_variable_finder/main_finder'
require 'problematic_variable_finder/problem'

module ProblematicVariableFinder
  class ProblemFinder
    include FsCaching

    def find_problems_in_directory(path, remove_paths=[])
      files = Dir.glob("#{path}/**/*.rb")
      files = files.map do |f|
        f.gsub("//", "/")
      end

      shortened_files = files.map do |f|
        shortened = f.dup
        remove_paths.each do |remove_path|
          shortened = shortened.gsub(remove_path, '')
        end

        [f, shortened]
      end

      shortened_files.reject! do |_, shortened|
        ignored_file_matches.any? do |to_reject|
          shortened.include?(to_reject)
        end
      end

      shortened_files.flat_map do |full, shortened|
        path, problems = find_file_problems(full, shortened)

        problems.map do |problem|
          Problem.new(
            full_path: full,
            type: problem[:type],
            filename: path,
            line_number: problem[:line_number],
            code: problem[:name].to_s
          )
        end
      end
    end

    def ignored_file_matches
      @ignored_file_matches ||= ProblematicVariableFinder.read_file(File.expand_path('DEFAULT_IGNORED_FILES', __dir__)).split("\n").map(&:strip)
    end

    def find_file_problems(full, shortened)
      full_path = File.expand_path(full)

      problems = begin
                   MainFinder.call(ProblematicVariableFinder.read_file(full_path))
                 rescue => e
                   puts "Error parsing #{full_path} #{e}"
                   []
                 end

      [shortened, problems]
    end
  end
end
