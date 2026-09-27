# frozen_string_literal: true

module Pennycress
  # Helpers for building cache keys.
  module Caching
    # Builds a cache key from key segments
    #
    # @param segments [Array<Object>] key segments
    # @return [String]
    def self.key(*segments)
      segments
        .compact
        .map(&:to_s)
        .reject(&:empty?)
        .join("/")
    end
  end
end
