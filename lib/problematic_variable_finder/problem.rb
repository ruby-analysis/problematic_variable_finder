module ProblematicVariableFinder
  class Problem
    attr_accessor \
      :gem_name,
      :gem_version,
      :filename,
      :line_number,
      :out_of_date,
      :type,
      :code

    def initialize(**attrs)
      attrs.each do |key, value|
        send("#{key}=", value)
      end
    end

    def github_link
      @github_link ||=
        begin
          if source_code_uri
            "#{source_code_uri}/#{filename}##{line_number}"
          else
            "#{gem_name} #{filename}##{line_number}"
          end
        end
    end

    def source_code_uri
      gem_spec&.metadata&.fetch('source_code_uri', nil)
    end

    def gem_spec
      return nil if gem_name.nil?

      @gem_spec ||= Gem::Specification.find_all_by_name(gem_name).find do |s| 
        s.version.to_s == gem_version
      end
    end
  end
end
