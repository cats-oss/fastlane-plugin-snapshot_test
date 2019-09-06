require 'fastlane/plugin/snapshot_test/version'

module Fastlane
  module SnapshotTest
    # Return all .rb files inside the "actions" and "helper" directory
    def self.all_classes
      Dir[File.expand_path(
          '**/actions/**/*.rb',
          '**/helper/*.rb',
          File.dirname(__FILE__)
      )]
    end
  end
end

# By default we want to import all available actions and helpers
# A plugin can contain any number of actions and plugins
Fastlane::SnapshotTest.all_classes.each do |current|
  require current
end
