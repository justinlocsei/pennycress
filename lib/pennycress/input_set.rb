# frozen_string_literal: true

require_relative "models"
require_relative "schema"

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
    # @return [Hash] inputs that conform to the schema
    # @raise [ValidationError] if the inputs are invalid
    def validate(inputs)
      Schema.validate_shape(schema, inputs)
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
