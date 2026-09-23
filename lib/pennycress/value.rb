# frozen_string_literal: true

require_relative "constraints"
require_relative "input_set"
require_relative "output"
require_relative "value_config"

module Pennycress
  # A value describes a computation performed on a set of inputs.  After the
  # initial value is computed, it is cached and reused until an invalidation
  # condition is met.
  class Value
    include Constraints

    class << self
      # Defines the value's inputs
      #
      # @param model_ids [Array<Symbol>] model IDs (e.g., `:uploaded_file, :user`)
      # @param other [Hash{Symbol => Class}] other input types (e.g., `name: String`)
      # @return [void]
      def inputs(*model_ids, **other)
        config.inputs = InputSet.new(model_ids: model_ids, named: other)
      end

      # Defines the value's output
      #
      # @param schema [Class, Hash{Symbol => Class}] a scalar type or shape hash
      # @return [void]
      # @raise [ArgumentError] if the schema is invalid
      def output(schema)
        config.output = Output.new(schema)
      end

      # Computes an output value for the given inputs
      #
      # @param inputs [Object]
      # @return [Object] the output value
      # @raise [ValidationError] if the inputs are invalid
      def fetch(**inputs)
        new.send(:fetch, **config.inputs.validate(inputs))
      end

      # Computes output values for a list of inputs
      #
      # @param all_inputs [Array<Object>]
      # @return [Array<Object>] the output values
      # @raise [ValidationError] if any inputs or outputs are invalid
      def fetch_many(all_inputs)
        validated = all_inputs.map do |inputs|
          config.inputs.validate(inputs)
        end

        new.send(:fetch_many, validated)
      end

    private

      # @return [ValueConfig]
      def config
        @config ||= ValueConfig.new
      end
    end

    # Computes an output value for valid inputs
    #
    # @return [Object]
    # @api value
    def compute(*)
      require_method(:compute)
    end

    # Computes output values for a list of valid inputs
    #
    # @param all_inputs [Array<Hash>] a list of valid inputs
    # @return [Array<Object>]
    # @api value
    def compute_many(all_inputs)
      all_inputs.map do |inputs|
        compute(**inputs)
      end
    end

  private

    # Computes an output value for valid inputs
    #
    # @param inputs [Object]
    # @return [Object] the output value
    def fetch(**inputs)
      output.validate(compute(**inputs))
    end

    # Computes output values for a list of valid inputs
    #
    # @param all_inputs [Array<Hash>] a list of valid inputs
    # @return [Array<Object>] the output values
    def fetch_many(all_inputs)
      compute_many(all_inputs).map do |result|
        output.validate(result)
      end
    end

    # @return [Output] the value's output schema
    def output
      @output ||= self.class.send(:config).output
    end
  end
end
