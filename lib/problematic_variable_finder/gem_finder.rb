require_relative './fs_caching'

module ProblematicVariableFinder
  class GemFinder
    include FsCaching

    class Gem
      def initialize(name, version, sha)
        @name = name
        @version = version
        @sha = sha
      end

      attr_reader :name, :version, :sha

      def name_and_version
        "#{name}-#{version}"
      end
    end

    def call
      cache "BUNDLE_INSTALL_#{gemfile_lock_sha}" do
        gems = `bundle list --only-group default production | grep '*'`.split("\n").map(&:chomp)

        gems = gems.map(&:strip).map do |s|
          match = s.match(/\* ([^ ]+) \(([^ ]+) ?([^ ]*)\)/)
          Gem.new(match[1], match[2], match[3])
        end

        first_gem = gems.first
        first_gem_path = `bundle show #{gems.first.name}`
        gem_path = first_gem_path.gsub(first_gem.name_and_version, '').strip.gsub(%r{/$}, "")

        [gem_path, gems]
      end
    end

    def gemfile_lock_sha
      return '1' if ProblematicVariableFinder.options.force_cache

      Digest::SHA1.hexdigest(File.read('Gemfile.lock'))
    end
  end
end
