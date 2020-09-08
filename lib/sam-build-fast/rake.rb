require_relative '../sam-build-fast'
require 'rake/tasklib'

module SamBuildFast
  module Rake
    def self.define(name = :sam, &block)
      options = Command::Options.new
      block.call(options) if block
      command = Command.new(options)

      build = ::Rake::Task.define_task(:"#{name}:build") do
        command.build
      end
      build.add_description('Build SAM application')

      clean = ::Rake::Task::define_task(:"#{name}:clean") do
        command.clean
      end
      clean.add_description('Clean SAM application for fresh rebuild')
    end
  end
end
