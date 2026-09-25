# frozen_string_literal: true

require "active_support/cache"
require "pennycress/configuration"

module Pennycress
  # Helpers for configuring Pennycress in specs.
  module TestHelpers
    # Runs a block with an in-memory cache configuration
    #
    # @param namespace [String, nil] the global cache namespace
    # @yield run examples against the temporary configuration
    # @return [Object] the block's return value
    def with_memory_cache(namespace: nil, &block)
      Configuration.override(
        build_memory_cache_config(namespace: namespace),
        &block
      )
    end

  private

    # Builds a configuration backed by an in-memory cache store
    #
    # @param namespace [String] the global cache key prefix
    # @return [Configuration]
    def build_memory_cache_config(namespace: "pennycress/test")
      Configuration.build do |config|
        config.cache = ActiveSupport::Cache::MemoryStore.new
        config.cache_namespace = namespace
      end
    end
  end
end
