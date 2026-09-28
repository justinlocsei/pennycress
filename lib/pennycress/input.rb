# frozen_string_literal: true

require_relative "model_reference"
require_relative "models"
require_relative "schema"

module Pennycress
  # An input describes a value's inputs models.
  class Input
    # @return [Array<Symbol>] the IDs of the models used by the value
    attr_reader :model_ids

    # Creates an input schema for a value
    #
    # @param model_ids [Array<Symbol>] model IDs (e.g., `[:uploaded_file, :user]`)
    def initialize(model_ids: [])
      @model_ids = model_ids.uniq.sort
    end

    # @return [Boolean] whether models are absent
    def empty?
      model_ids.empty?
    end

    # Validates an input against the schema
    #
    # @param input [Object] user-provided input
    # @return [Hash] an input that conforms to the schema
    # @raise [ValidationError] if the input is invalid
    def validate(input)
      Schema.validate_shape(schema, input) do |key, value|
        ModelReference.from(schema[key], value, label: key.to_s)
      end
    end

  private

    # @return [Hash{Symbol => Class}] a mapping of IDs to model classes
    def schema
      @schema ||= model_ids.to_h do |id|
        [id, Pennycress::Models.resolve(id)]
      end
    end
  end
end
