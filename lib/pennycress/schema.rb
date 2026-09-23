# frozen_string_literal: true

require_relative "errors"

module Pennycress
  # This module provides a collection of helpers for validating user-provided
  # values against type and shape constraints.
  module Schema
    class << self
      # Ensures that a value conforms to a given shape
      #
      # @param shape [Hash{Symbol => Class}] the shape to validate against
      # @param value [Object] the value to validate
      # @return [Hash] a value that conforms to the shape
      # @raise [ValidationError] if the value is invalid
      def validate_shape(shape, value)
        unless value.is_a?(Hash)
          raise ValidationError, "value is not a hash: #{value.inspect}"
        end

        errors = shape.keys.filter_map do |key|
          "missing key: #{key}" unless value.key?(key)
        end

        errors += value.filter_map do |key, item|
          if shape.key?(key)
            check_type(shape[key], item, label: key.to_s)
          else
            "unknown key: #{key}"
          end
        end

        unless errors.empty?
          raise ValidationError, errors.sort.join("\n")
        end

        value
      end

      # Ensures that a value is an instance of a type
      #
      # @param type [Class] the type to validate against
      # @param value [Object] the value to validate
      # @return [Object] an instance of the type
      # @raise [ValidationError] if the value is invalid
      def validate_type(type, value)
        error = check_type(type, value, label: "value")

        raise ValidationError, error if error

        value
      end

    private

      # Produces an error message if a value is not a given type
      #
      # @param type [Class] the type to validate against
      # @param value [Object] the value to validate
      # @param label [String] a custom label for the value
      # @return [String, nil] an error message if the value is not a given type
      def check_type(type, value, label:)
        return if value.is_a?(type)

        "#{label} is not an instance of #{type.name}: #{value.inspect}"
      end
    end
  end
end
