# frozen_string_literal: true

require_relative "value_config"

module Pennycress
  # A value describes a computation performed on a set of inputs.  After the
  # initial value is computed, it is cached and reused until an invalidation
  # condition is met.
  class Value
    class << self
      # Defines the inputs from which the value is derived
      #
      # @param model_ids [Array<Symbol>] model IDs (e.g., `:uploaded_file, :user`)
      # @param other [Hash{Symbol => Class}] other input types (e.g., `name: String`)
      # @return [void]
      def derived_from(*model_ids, **other)
        inputs = config.inputs

        inputs.model_ids = model_ids
        inputs.named = other
      end

    private

      # @return [ValueConfig] configuration for the value
      def config
        @config ||= ValueConfig.new
      end
    end
  end
end
