# frozen_string_literal: true

module Pennycress
  # An output reference identifies a cached output for a computed value produced
  # from a single input.
  class OutputReference
    # @return [Hash] a validated input
    attr_reader :input

    # Creates an output reference
    #
    # @param input [Hash] a validated input
    # @param namespace [String, nil] a namespace that contains the value's outputs
    def initialize(input:, namespace: nil)
      @input = input
      @namespace = namespace
    end

    # @return [String] the cache key for this reference
    def cache_key
      @cache_key ||= [@namespace, *input_key_segments].compact.reject(&:empty?).join("/")
    end

  private

    # @return [Array<String>] segments in the cache key for the input
    def input_key_segments
      input.keys.sort.filter_map do |key|
        value = input[key]
        value && value_to_key(value).downcase
      end
    end

    # @param value [Object] an input value
    # @return [String] a serialized key segment
    def value_to_key(value)
      value.id.to_s
    rescue NoMethodError
      value.to_s
    end
  end
end
