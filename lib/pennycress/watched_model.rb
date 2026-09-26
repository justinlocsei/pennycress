# frozen_string_literal: true

require_relative "models"

module Pennycress
  # A watched model describes a model observed by a value.  When the model
  # changes, a value has the chance to selectively invalidate itself by deriving
  # inputs from the changed model.
  class WatchedModel
    # @return [Symbol] the ID of the watched model
    attr_reader :id

    # @return [Proc] a block that maps a model to inputs
    attr_reader :inputs

    # Creates a watched model
    #
    # @param id [Symbol] the ID of the model to watch
    # @yieldparam model [ActiveRecord::Base] the changed model instance
    # @yieldreturn [Enumerable<Hash>] inputs to refresh
    def initialize(id, &inputs)
      @id = id
      @inputs = inputs
    end

    # @return [Class] the watched ActiveRecord model class
    def model_class
      @model_class ||= Models.resolve(id)
    end

    # Produces invalidation inputs for a given model
    #
    # @param model [ActiveRecord::Base] a changed model instance
    # @return [Enumerable<Hash>] invalidation inputs
    def inputs_for(model)
      inputs.call(model)
    end
  end
end
