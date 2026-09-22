# frozen_string_literal: true

require "set"

require_relative "errors"
require_relative "models"

module Pennycress
  # An input set is a container for a value's inputs.  It tracks both models
  # and optional named inputs, if the value is derived from Ruby primitives.
  class InputSet
    # @return [Hash{Symbol => Class}] a mapping of source IDs to Ruby value classes
    attr_accessor :named

    # Creates a container for a value's inputs
    def initialize
      @model_ids = Set.new
      @named = {}
    end

    # @return [Array<Symbol>] the IDs of the models from which a value is derived
    def model_ids
      @model_ids.to_a.sort
    end

    # Sets the IDs of the input models
    #
    # @param ids [Array<Symbol>] model IDs (e.g., `:uploaded_file, :user`)
    # @return [void]
    def model_ids=(ids)
      @model_ids = ids.to_set
    end

    # Validates inputs against the current set's schema
    #
    # @param inputs [Object] user-provided inputs
    # @return [Object] inputs that conform to the schema
    # @raise [ValidationError] if the inputs are invalid
    def validate(inputs)
      unless inputs.is_a?(Hash)
        raise ValidationError, "inputs must be a hash: #{inputs.inspect}"
      end

      errors = schema.keys.filter_map do |key|
        "missing input: #{key}" unless inputs.key?(key)
      end

      errors += inputs.filter_map do |key, value|
        if !schema.key?(key)
          "unknown input: #{key}"
        elsif !value.is_a?(schema[key])
          "#{key} must be an instance of #{schema[key].name}: #{value.inspect}"
        end
      end

      unless errors.empty?
        raise ValidationError, errors.sort.join("\n")
      end

      inputs
    end

  private

    # @return [Hash{Symbol => Class}] a mapping ofsource IDs to Ruby value classes
    def schema
      @schema ||= model_ids
        .to_h { |id| [id, Pennycress::Models.resolve(id)] }
        .merge(named)
    end
  end
end
