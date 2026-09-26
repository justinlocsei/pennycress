# frozen_string_literal: true

require_relative "models"

module Pennycress
  # A watched model describes a model observed by a value.  When the model
  # changes, a value has the chance to selectively invalidate itself by deriving
  # inputs from the changed model.
  class WatchedModel
    # Commit actions a watch can respond to
    ACTIONS = %i[create destroy update].freeze

    # @return [Symbol] the ID of the watched model
    attr_reader :id

    # @return [Proc] a block that maps a model to inputs
    attr_reader :inputs

    # @return [Array<Symbol>] commit actions that trigger invalidation
    attr_reader :on

    # Creates a watched model
    #
    # @param id [Symbol] the ID of the model to watch
    # @param on [Array<Symbol>] commit actions that trigger invalidation
    # @yieldparam model [ActiveRecord::Base] the changed model instance
    # @yieldreturn [Enumerable<Hash>] inputs to refresh
    # @raise [ArgumentError] if the commit actions are invalid
    def initialize(id, on: ACTIONS, &inputs)
      @id = id
      @inputs = inputs
      @on = validate_actions(on)
    end

    # Produces invalidation inputs for a given model
    #
    # @param model [ActiveRecord::Base] a changed model instance
    # @return [Enumerable<Hash>] invalidation inputs
    def inputs_for(model)
      inputs.call(model)
    end

    # @return [Class] the watched ActiveRecord model class
    def model_class
      @model_class ||= Models.resolve(id)
    end

  private

    # Validates commit actions
    #
    # @param actions [Array<Symbol>]
    # @return [Array<Symbol>] valid commit actions
    def validate_actions(actions)
      if actions.empty?
        raise ArgumentError, "commit actions cannot be empty"
      end

      unknown = actions - ACTIONS

      unless unknown.empty?
        raise ArgumentError, "unsupported commit actions: #{unknown.map(&:inspect).join(', ')}"
      end

      actions.uniq.sort
    end
  end
end
