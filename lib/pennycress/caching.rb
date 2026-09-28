# frozen_string_literal: true

module Pennycress
  # This module defines helpers for building cache keys.
  module Caching
    # Builds a cache key from segments
    #
    # @param segments [Array<Object>]
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
