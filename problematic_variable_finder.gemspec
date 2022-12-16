# frozen_string_literal: true

require_relative "lib/problematic_variable_finder/version"

Gem::Specification.new do |spec|
  spec.name          = "problematic_variable_finder"
  spec.version       = ProblematicVariableFinder::VERSION
  spec.authors       = ["Mark Burns"]
  spec.email         = ["markburns@users.noreply.github.com"]

  spec.summary       = "Find thread safety issues"
  spec.description   = "Static analysis tool to find class instance variables, class variables, global variables, and class accessors"
  spec.homepage      = "https://github.com/ruby-analysis/problematic_variable_finder"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["allowed_push_host"] = "'https://rubygems.org'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/ruby-analysis/problematic_variable_finder/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport'
  spec.add_dependency 'parser'
end
