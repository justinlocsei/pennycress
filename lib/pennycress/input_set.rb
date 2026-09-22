# frozen_string_literal: true

require_relative "errors"
require_relative "models"

module Pennycress
  # An input set is a container for a value's inputs.  It tracks both models
  # and optional named inputs, if the value is derived from Ruby primitives.
  class InputSet
    # @return [Array<Symbol>] the IDs of the models from which a value is derived
    attr_reader :model_ids

    # @return [Hash{Symbol => Class}] a mapping of source IDs to Ruby value classes
    attr_reader :named

    # Creates a container for a value's inputs
    #
    # @param model_ids [Array<Symbol>] model IDs (e.g., `:uploaded_file, :user`)
    # @param named [Hash{Symbol => Class}] named inputs (e.g., `{ id: Integer }`)
    def initialize(model_ids: [], named: {})
      @model_ids = model_ids.uniq.sort
      @named = named
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

    # @return [Hash{Symbol => Class}] a mapping of source IDs to Ruby value classes
    def schema
      @schema ||= model_ids
        .to_h { |id| [id, Pennycress::Models.resolve(id)] }
        .merge(named)
    end
  end
end
