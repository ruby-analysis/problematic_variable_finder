# frozen_string_literal: true
require 'parser/current'
require 'active_support/all'
require 'pstore'

require "problematic_variable_finder/runner"
require "problematic_variable_finder/main_finder"

module ProblematicVariableFinder
  def self.run
    Runner.call
  end
end
