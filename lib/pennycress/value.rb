# frozen_string_literal: true

require_relative "constraints"
require_relative "input"
require_relative "output"
require_relative "value_config"

module Pennycress
  # A value describes a computation performed for each distinct input.  After
  # the initial value is computed, it is cached and reused until an invalidation
  # condition is met.
  class Value
    include Constraints

    class << self
      # Defines the value's input contract
      #
      # @param model_ids [Array<Symbol>] model IDs (e.g., `:uploaded_file, :user`)
      # @param other [Hash{Symbol => Class}] other field types (e.g., `name: String`)
      # @return [void]
      def input(*model_ids, **other)
        config.input = Input.new(model_ids: model_ids, named: other)
      end

      # Defines the value's output
      #
      # @param schema [Class, Hash{Symbol => Class}] a scalar type or shape hash
      # @return [void]
      # @raise [ArgumentError] if the schema is invalid
      def output(schema)
        config.output = Output.new(schema)
      end

      # Defines or returns the value's seeds
      #
      # @yieldreturn [Enumerable<Object>] a list of seeds to warm
      # @return [Enumerable<Object>] the defined seeds, when called without a block
      # @raise [ValidationError] if seeds are not defined
      def seeds(&block)
        if block
          config.seeds = block
        else
          class_eval(&config.seeds)
        end
      end

      # Computes an output value for the given input
      #
      # @param input [Hash] keyword arguments identifying one value instance
      # @return [Object] the output value
      # @raise [ValidationError] if the input is invalid
      def fetch(**input)
        new.send(:fetch, **config.input.validate(input))
      end

      # Computes output values for each input in an enumerable
      #
      # @param inputs [Enumerable<Hash>] inputs to compute
      # @return [Array<Object>] output values
      # @raise [ValidationError] if any inputs or outputs are invalid
      def fetch_many(inputs)
        validated = inputs
          .lazy
          .map { |input| config.input.validate(input) }

        new.send(:fetch_many, validated).to_a
      end

    private

      # @return [ValueConfig]
      def config
        @config ||= ValueConfig.new
      end
    end

    # Computes an output value for a valid input
    #
    # @return [Object]
    # @api value
    def compute(*)
      require_method(:compute)
    end

    # Computes output values for each input in an enumerable
    #
    # @param inputs [Enumerable<Hash>] valid inputs to compute
    # @return [Enumerable<Object>] output values
    # @api value
    def compute_many(inputs)
      inputs.map do |input|
        compute(**input)
      end
    end

    # Converts a seed to a list of inputs
    #
    # @return [Enumerable<Hash>]
    # @api value
    def seed_to_inputs(*)
      require_method(:seed_to_inputs)
    end

  private

    # Computes an output value for a valid input
    #
    # @param input [Hash] a valid input
    # @return [Object] the output value
    def fetch(**input)
      output.validate(compute(**input))
    end

    # Computes output values for each input in an enumerable
    #
    # @param inputs [Enumerable<Hash>] valid inputs
    # @return [Enumerable<Object>] output values
    def fetch_many(inputs)
      compute_many(inputs).map do |result|
        output.validate(result)
      end
    end

    # @return [Output] the value's output schema
    def output
      @output ||= self.class.send(:config).output
    end
  end
end
