# frozen_string_literal: true

require "rails/railtie"

module Pennycress
  # This Railtie integrates Pennycress with Rails.
  class Railtie < ::Rails::Railtie
    DEFAULT_DIRECTORIES = ["app/values"].freeze
    private_constant :DEFAULT_DIRECTORIES

    initializer "pennycress.directories", after: :load_config_initializers do
      Pennycress.configure do |config|
        config.directories = Configuration.expand_paths(
          Rails.root,
          config.directories.empty? ? DEFAULT_DIRECTORIES : config.directories
        )
      end
    end
  end
end
