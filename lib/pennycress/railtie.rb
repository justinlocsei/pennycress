# frozen_string_literal: true

require "rails/railtie"
require_relative "configuration"
require_relative "integration"
require_relative "registry"

module Pennycress
  # This Railtie integrates Pennycress with Rails.
  class Railtie < ::Rails::Railtie
    DEFAULT_DIRECTORIES = ["app/values"].freeze
    private_constant :DEFAULT_DIRECTORIES

    initializer "pennycress.directories", after: :load_config_initializers do
      config = Configuration.current

      config.directories = Configuration.expand_paths(
        Rails.root,
        config.directories.empty? ? DEFAULT_DIRECTORIES : config.directories
      )
    end

    config.to_prepare do
      Registry.current.reset
      Integration.load_values(Configuration.current.directories)
      Integration.watch_models
    end
  end
end
