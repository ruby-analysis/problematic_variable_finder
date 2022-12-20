# frozen_string_literal: true
require 'parser/current'
require 'active_support/all'
require 'pstore'
require 'ostruct'

require "problematic_variable_finder/runner"
require "problematic_variable_finder/main_finder"
require "problematic_variable_finder/monkey_patches"

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

    def options
      @options ||= OpenStruct.new(parse_options)
    end

    private

    def parse_options
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on("-fFORMAT", "--format=FORMAT", "output format default stdout, options [csv]") do |f|
          options[:format] = (f || 'stdout').to_sym
        end

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          options[:verbose] = v
        end

        opts.on("-d", "--directory", "Directory to find app in") do |d|
          options[:directory] = d
        end

        opts.on("-i", "--ignore rails,activerecord", Array, "Ignore gems") do |i|
          options[:ignore] = i
        end

        opts.on("-g", "--gems rails,activerecord", Array, "List of gems") do |g|
          options[:gems] = g
        end
      end.parse!

      options
    end

  end
end
