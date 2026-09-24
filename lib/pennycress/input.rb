# frozen_string_literal: true

require_relative "models"
require_relative "schema"

module Pennycress
  # An input describes a value's input contract.  It tracks both models and
  # optional named fields that allow a value to take arbitrary Ruby classes.
  class Input
    # @return [Array<Symbol>] the IDs of the models used by the value
    attr_reader :model_ids

    # @return [Hash{Symbol => Class}] a mapping of source IDs to Ruby value classes
    attr_reader :named

    # Creates an input contract for a value
    #
    # @param model_ids [Array<Symbol>] model IDs (e.g., `:uploaded_file, :user`)
    # @param named [Hash{Symbol => Class}] named fields (e.g., `{ id: Integer }`)
    def initialize(model_ids: [], named: {})
      @model_ids = model_ids.uniq.sort
      @named = named
    end

    # @return [Boolean] whether models and types are absent
    def empty?
      model_ids.empty? && named.empty?
    end

    # Validates an input against the contract
    #
    # @param input [Hash] user-provided input
    # @return [Hash] input that conforms to the contract
    # @raise [ValidationError] if the input is invalid
    def validate(input)
      Schema.validate_shape(schema, input)
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
