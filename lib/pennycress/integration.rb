# frozen_string_literal: true

require "active_support/concern"
require_relative "registry"

module Pennycress
  # Integrates Pennycress with a Rails application.
  module Integration
    # A concern included on watched models that adds a post-commit hook to
    # trigger invalidation.
    module ModelCommitHandler
      extend ActiveSupport::Concern

      included do
        after_commit { Integration.handle_commit(self) }
      end
    end

    class << self
      # Respond to a commit on a watched model
      #
      # @param record [ActiveRecord::Base] a committed model instance
      # @return [void]
      def handle_commit(record)
        model_handlers[record.class].each do |handler|
          handler.call(record)
        end
      end

      # Search for value files from the given directories
      #
      # The directories should contain Value definitions.  When loaded, these
      # definitions will be added to the value registry.
      #
      # @param directories [Array<String>] absolute directory paths
      # @return [void]
      # @raise [ArgumentError] if a path is not a directory
      def load_values(directories)
        directories.each do |directory|
          unless File.directory?(directory)
            raise ArgumentError, "path is not a directory: #{directory}"
          end

          Dir
            .glob(File.join(directory, "**", "*.rb"))
            .sort
            .each { |file| load file }
        end
      end

      # Add callbacks to all watched models
      #
      # @return [void]
      def watch_models
        model_handlers.clear

        Registry.current.values.each do |value_class|
          value_class.config.watches.each do |watch|
            model = watch.model_class

            model_handlers[model] << lambda do |record|
              value_class.invalidate(watch, record)
            end
          end
        end

        model_handlers.each_key do |model|
          unless model.include?(ModelCommitHandler)
            model.include(ModelCommitHandler)
          end
        end
      end

    private

      # @return [Hash{Class => Array<Proc>}] a mapping of model classes to invalidation handlers
      def model_handlers
        @model_handlers ||= Hash.new do |hash, key|
          hash[key] = []
        end
      end
    end
  end
end
