# frozen_string_literal: true

require "active_support/cache/null_store"

module Pennycress
  # The configuration stores all global settings for Pennycress.
  class Configuration
    class << self
      # Builds a new configuration
      #
      # @yieldparam config [Configuration] the configuration to customize
      # @return [Configuration] the built configuration
      def build
        config = new
        yield config
        config
      end

      # @return [Configuration] the current configuration
      def current
        @current ||= new
      end

      # Runs a block with a temporary configuration
      #
      # @param config [Configuration] the configuration to use
      # @yield run a block in which the given configuration is the current one
      # @return [Object] the block's return value
      def override(config)
        previous = @current
        @current = config

        yield
      ensure
        @current = previous
      end
    end

    # @!attribute [rw] cache_namespace
    #   @return [String] a global prefix for cache keys
    attr_accessor :cache_namespace

    # @!attribute [w] cache
    #   @param value [ActiveSupport::Cache::Store]
    attr_writer :cache

    # Creates a configuration
    def initialize
      @cache_namespace = "pennycress"
    end

    # @return [ActiveSupport::Cache::Store] the cache store to use
    def cache
      @cache ||= ActiveSupport::Cache::NullStore.new
    end
  end
end
