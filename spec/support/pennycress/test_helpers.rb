# frozen_string_literal: true

require "active_support/cache"
require "pennycress/configuration"

module Pennycress
  # Helpers for configuring Pennycress in specs.
  module TestHelpers
    # Runs a block with an in-memory cache configuration
    #
    # @param namespace [String] the global cache namespace
    # @yield run examples against the temporary configuration
    # @return [Object] the block's return value
    def with_memory_cache(namespace: "pennycress/test", &block)
      Configuration.override(
        build_memory_cache_config(namespace),
        &block
      )
    end

    # Runs a block with a temporary global cache namespace
    #
    # @param namespace [String] the global cache namespace
    # @yield run examples against the temporary configuration
    # @return [Object] the block's return value
    def with_cache_namespace(namespace, &block)
      config = Configuration.modify do |built|
        built.cache_namespace = namespace
      end

      Configuration.override(config, &block)
    end

  private

    # Builds a configuration backed by an in-memory cache store
    #
    # @param namespace [String] the global cache key prefix
    # @return [Configuration]
    def build_memory_cache_config(namespace)
      Configuration.modify do |config|
        config.cache = ActiveSupport::Cache::MemoryStore.new
        config.cache_namespace = namespace
      end
    end
  end
end
