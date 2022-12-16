require_relative './fs_caching'

class GemFinder
  include FsCaching

  def call
    cache 'BUNDLE_INSTALL' do
      `bundle install --with=production --without="development test"`

      gems = `bundle list | grep '*'`.split("\n").map{|s| s.gsub(/ *\* /, "")}
      gems = gems.map{|g| g.split("(")}.map{|name, version| [name.strip, version.gsub(")", '').strip]}
      first = `bundle show #{gems.first.first}`
      gem_path = first.gsub(gems.first.join('-'), '').strip.gsub(%r{/$}, "")

      [gem_path,  gems]
    end
  end
end
