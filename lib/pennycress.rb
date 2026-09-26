# frozen_string_literal: true

require_relative "pennycress/configuration"
require_relative "pennycress/version"

require_relative "pennycress/railtie" if defined?(Rails::Railtie)

# Pennycress allows Rails apps to precompute and cache expensive logic, with
# fine-grained invalidation and support for targeted cache warming.
module Pennycress
  class << self
    # Configures Pennycress
    #
    # @yieldparam config [Configuration] the current configuration
    # @return [void]
    def configure
      yield Configuration.current
    end
  end
end
