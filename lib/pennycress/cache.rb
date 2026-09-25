# frozen_string_literal: true

module Pennycress
  # A cache is a thin wrapper around an ActiveSupport cache store that uses
  # specialized output references for all cache operations.
  class Cache
    WRITE_OPTIONS = { skip_nil: true }.freeze
    private_constant :WRITE_OPTIONS

    # Creates a cache
    #
    # @param store [ActiveSupport::Cache::Store] the backing cache store
    def initialize(store)
      @store = store
    end

    # Evicts a cached value
    #
    # @param reference [OutputReference]
    # @return [void]
    def evict(reference)
      @store.delete(reference.cache_key)
    end

    # Evicts cached values
    #
    # @param references [Array<OutputReference>]
    # @return [void]
    def evict_many(references)
      @store.delete_multi(references.map(&:cache_key))
    end

    # Reads a cached value, computing and storing it when absent
    #
    # @param reference [OutputReference]
    # @yieldreturn [Object] the value to cache in the case of a cache miss
    # @return [Object] the cached or computed value
    def fetch(reference, &)
      @store.fetch(reference.cache_key, **WRITE_OPTIONS, &)
    end

    # Reads a set of cached values, computing and storing misses
    #
    # @param references [Array<OutputReference>]
    # @yieldparam reference [OutputReference] a reference that was not cached
    # @yieldreturn [Object] the value to cache for the reference
    # @return [Array<Object>] cached or computed values in reference order
    def fetch_multi(references)
      keys = references.map(&:cache_key)
      refs_by_key = keys.zip(references).to_h

      cached = @store.fetch_multi(*keys, **WRITE_OPTIONS) do |key|
        yield refs_by_key.fetch(key)
      end

      keys.map { |key| cached.fetch(key) }
    end

    # Writes a value to the cache
    #
    # @param reference [OutputReference]
    # @param value [Object] the value to cache
    # @return [void]
    def write(reference, value)
      @store.write(reference.cache_key, value, **WRITE_OPTIONS)
    end

    # Writes multiple values to the cache
    #
    # @param entries [Hash{OutputReference => Object}]
    # @return [void]
    def write_multi(entries)
      @store.write_multi(
        entries.transform_keys(&:cache_key),
        **WRITE_OPTIONS
      )
    end
  end
end
