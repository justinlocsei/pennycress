# frozen_string_literal: true

require_relative "constraints"
require_relative "input_set"
require_relative "value_config"

module Pennycress
  # A value describes a computation performed on a set of inputs.  After the
  # initial value is computed, it is cached and reused until an invalidation
  # condition is met.
  class Value
    include Constraints

    class << self
      # Defines the inputs from which the value is derived
      #
      # @param model_ids [Array<Symbol>] model IDs (e.g., `:uploaded_file, :user`)
      # @param other [Hash{Symbol => Class}] other input types (e.g., `name: String`)
      # @return [void]
      def derived_from(*model_ids, **other)
        config.inputs = InputSet.new(model_ids: model_ids, named: other)
      end

      # Calculates an ouptut value for the given inputs
      #
      # @param inputs [Object]
      # @return [Object] the output value
      # @raise [ValidationError] if the inputs are invalid
      def fetch(**inputs)
        new.send(:fetch, **config.inputs.validate(inputs))
      end

    private

      # @return [ValueConfig] configuration for the value
      def config
        @config ||= ValueConfig.new
      end
    end

    # Calculates an output value for valid inputs
    #
    # @return [Object] the output value
    # @api value
    def derive(*)
      require_method(:derive)
    end

  private

    # Calculates an output value for valid inputs
    #
    # @param inputs [Object]
    # @return [Object] the output value
    def fetch(**inputs)
      derive(**inputs)
    end
  end
end
