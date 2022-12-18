require_relative './fs_caching'

module ProblematicVariableFinder
  class GemFinder
    include FsCaching

    def call
      cache "BUNDLE_INSTALL_#{gemfile_lock_sha}" do
        `bundle config set --local with "production"`
        `bundle config set --local without "development test"`
        `bundle install `

        gems = `bundle list | grep '*'`.split("\n").map{|s| s.gsub(/ *\* /, "")}
        gems = gems.map{|g| g.split("(")}.map{|name, version| [name.strip, version.gsub(")", '').strip]}
        first = `bundle show #{gems.first.first}`
        gem_path = first.gsub(gems.first.join('-'), '').strip.gsub(%r{/$}, "")

        [gem_path, gems]
      end
    end

    def gemfile_lock_sha
      Digest::SHA1.hexdigest(File.read('Gemfile.lock'))
    end
  end
end
