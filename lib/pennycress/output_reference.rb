# frozen_string_literal: true

require_relative "caching"
require_relative "model_reference"

module Pennycress
  # An output reference identifies a cached output for a computed value produced
  # from a single input.
  class OutputReference
    # Creates an output reference
    #
    # @param input [Hash] a validated input
    # @param namespace [String, nil] a namespace that contains the value's outputs
    def initialize(input:, namespace: nil)
      @raw_input = input
      @namespace = namespace
    end

    # @return [String] the cache key for this reference
    def cache_key
      @cache_key ||= Caching.key(@namespace, *input_key_segments)
    end

    # @return [Hash] the input in a form suitable for computing an output value
    def input
      @input ||= @raw_input.transform_values do |value|
        value.is_a?(ModelReference) ? value.record : value
      end
    end

  private

    # @return [Array<String>] segments in the cache key for the input
    def input_key_segments
      @raw_input.keys.sort.flat_map do |key|
        value = @raw_input[key]
        next [] unless value

        value_to_key(value).map(&:downcase)
      end
    end

    # @param value [Object] an input value
    # @return [Array<String>] serialized key segments
    def value_to_key(value)
      value.is_a?(ModelReference) ? value.cache_key : [value.id.to_s]
    rescue NoMethodError
      [value.to_s]
    end
  end
end
