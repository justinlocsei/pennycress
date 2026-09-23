# frozen_string_literal: true

require_relative "schema"

module Pennycress
  # An output describes the type or shape of a value's computed result.
  class Output
    # Creates a description of a value's output
    #
    # @param schema [Class, Hash{Symbol => Class}] a scalar type or shape hash
    # @raise [ArgumentError] if the schema is invalid
    def initialize(schema)
      if schema.is_a?(Class)
        @type = schema
      elsif schema.is_a?(Hash)
        @shape = schema
      else
        raise ArgumentError, "output must be a type or a shape hash"
      end
    end

    # Validates a computed result against the output's schema
    #
    # @param value [Object] a computed result
    # @return [Object] a value that conforms to the schema
    # @raise [ValidationError] if the value is invalid
    def validate(value)
      if @type
        Schema.validate_type(@type, value)
      else
        Schema.validate_shape(@shape, value)
      end
    end
  end
end
