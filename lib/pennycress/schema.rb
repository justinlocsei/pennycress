# frozen_string_literal: true

require_relative "errors"

module Pennycress
  # This module provides a collection of helpers for validating user-provided
  # values against type and shape constraints.
  module Schema
    class << self
      # Ensures that a value conforms to a given shape
      #
      # When a block is given, it is called for each shaped field with the key
      # and value.  The block may return a normalized value or raise
      # {ValidationError} for an invalid field.
      #
      # @param shape [Hash{Symbol => Class}] the shape to validate against
      # @param value [Object] the value to validate
      # @yieldparam key [Symbol] a shaped field key
      # @yieldparam item [Object] the field value
      # @yieldreturn [Object] a normalized field value
      # @return [Hash] the input value, or normalized values when a block is given
      # @raise [ValidationError] if the value is invalid
      def validate_shape(shape, value)
        unless value.is_a?(Hash)
          raise ValidationError, "value is not a hash: #{value.inspect}"
        end

        errors = shape.keys.filter_map do |key|
          "missing key: #{key}" unless value.key?(key)
        end

        normalized = {}

        errors += value.filter_map do |key, item|
          if shape.key?(key)
            if block_given?
              begin
                normalized[key] = yield(key, item)
                nil
              rescue ValidationError => e
                e.message
              end
            else
              check_type(shape[key], item, label: key.to_s)
            end
          else
            "unknown key: #{key}"
          end
        end

        unless errors.empty?
          raise ValidationError, errors.sort.join("\n")
        end

        block_given? ? normalized : value
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
