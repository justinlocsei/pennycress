# frozen_string_literal: true

require_relative "configuration"
require_relative "output_reference"

module Pennycress
  # A cache is a thin wrapper around an ActiveSupport cache store that uses
  # specialized output references for all cache operations.
  class Cache
    # Creates a cache
    #
    # @param store [ActiveSupport::Cache::Store] the backing cache store
    def initialize(store: Configuration.current.cache)
      @store = store
    end

    # Deletes a cached value
    #
    # @param reference [OutputReference] the output reference to delete
    # @return [Boolean] whether an entry was removed
    def delete(reference)
      @store.delete(reference.cache_key)
    end

    # Reads a cached value, computing and storing it when absent
    #
    # @param reference [OutputReference] the output reference to fetch
    # @yieldreturn [Object] the value to cache in the case of a cache miss
    # @return [Object] the cached or computed value
    def fetch(reference, &)
      @store.fetch(reference.cache_key, &)
    end

    # Writes a value to the cache
    #
    # @param reference [OutputReference] the output reference to write
    # @param value [Object] the value to cache
    # @return [Boolean] whether the write succeeded
    def write(reference, value)
      @store.write(reference.cache_key, value)
    end
  end
end
