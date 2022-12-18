# frozen_string_literal: true
require 'parser/current'
require 'active_support/all'
require 'pstore'

require "problematic_variable_finder/runner"
require "problematic_variable_finder/main_finder"

module ProblematicVariableFinder
  class << self
    include FsCaching

    def run
      Runner.call
    end

    def read_file(path)
      @files ||= {}
      @files[path] ||= File.read(path)
    end
  end
end
