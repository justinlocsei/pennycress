# frozen_string_literal: true

require "set"

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
    # @param ids [Array<Symbol>] model IDs (e.g., :uploaded_file, :user)
    # @return [void]
    def model_ids=(ids)
      @model_ids = ids.to_set
    end
  end
end
