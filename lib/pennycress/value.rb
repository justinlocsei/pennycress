# frozen_string_literal: true

require_relative "cache"
require_relative "configuration"
require_relative "constraints"
require_relative "input"
require_relative "output"
require_relative "output_reference"
require_relative "registry"
require_relative "value_config"
require_relative "watched_model"

module Pennycress
  # A value describes a computation performed for each distinct input.  After
  # the initial value is computed, it is cached and reused until an invalidation
  # condition is met.
  class Value
    include Constraints

    class << self
      # @param value [Class] the value being defined
      # @return [void]
      def inherited(value)
        super
        Registry.current.register(value)
      end

      # @return [ValueConfig] the value's configuration
      def config
        @config ||= ValueConfig.new
      end

      # Computes an output value for the given input
      #
      # @param inspect_reference [Proc, nil] expose the output reference used for retrieval
      # @param input [Hash] keyword arguments that should conform to the input schema
      # @return [Object] the output value
      # @raise [ValidationError] if the input is invalid
      def fetch(inspect_reference: nil, **input)
        ref = reference(**input)
        inspect_reference&.call(ref)

        cache.fetch(ref) do
          new.send(:fetch, **ref.input)
        end
      end

      # Computes an output value for each input in an enumerable
      #
      # @param inputs [Enumerable<Hash>] a list of keyword arguments for inputs
      # @return [Array<Object>] output values
      # @raise [ValidationError] if any inputs or outputs are invalid
      def fetch_many(inputs)
        new.send(:fetch_many, cache, inputs).to_a
      end

      # Defines the value's input schema
      #
      # @param model_ids [Array<Symbol>] model IDs (e.g., `:uploaded_file, :user`)
      # @param other [Hash{Symbol => Class}] other field types (e.g., `name: String`)
      # @return [void]
      def input(*model_ids, **other)
        config.input = Input.new(model_ids: model_ids, named: other)
      end

      # Defines the value's output schema
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
      def seeds(&block)
        if block
          config.seeds = block
        else
          class_eval(&config.seeds)
        end
      end

      # Registers a watch on a model
      #
      # @param id [Symbol] the model ID to watch (e.g., `:discussion`)
      # @yieldparam model [ActiveRecord::Base] the changed model instance
      # @yieldreturn [Enumerable<Hash>] inputs to refresh
      # @return [void]
      def watch(id, &inputs)
        config.watches << WatchedModel.new(id, &inputs)
      end

      # Warms the cache for each seed
      #
      # @return [void]
      def warm
        value = new
        seeds.each { |seed| value.warm_seed(seed) }
      end

    private

      # @return [Cache] the value's cache
      def cache
        @cache ||= Cache.new(Configuration.current.cache)
      end

      # @return [String] the value's cache namespace
      def cache_namespace
        @cache_namespace ||= if name
          name.split("::").map(&:downcase).join("/")
        else
          ""
        end
      end

      # Builds an output reference for the given input
      #
      # @param input [Hash] keyword arguments that should conform to the input schema
      # @return [OutputReference] a reference to the cached output
      # @raise [ValidationError] if the input is invalid
      def reference(**input)
        validated = config.input.validate(input)

        namespace = [Configuration.current.cache_namespace, cache_namespace]
          .compact
          .reject(&:empty?)
          .join("/")

        OutputReference.new(
          input: validated,
          namespace: namespace.empty? ? nil : namespace
        )
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
    # @param inputs [Enumerable<Hash>] a list of valid inputs
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

    # Warms the cache for a seed
    #
    # @param seed [Object]
    # @return [void]
    def warm_seed(seed)
      self.class.send(:fetch_many, seed_to_inputs(seed)).each { nil }
    end

  private

    # Computes an output value for a valid input
    #
    # @param input [Hash] a valid input
    # @return [Object] the output value
    def fetch(**input)
      output.validate(compute(**input))
    end

    # Computes an output value for each input in an enumerable
    #
    # @param cache [Cache]
    # @param inputs [Enumerable<Hash>] inputs to validate and compute
    # @return [Array<Object>] output values
    def fetch_many(cache, inputs)
      refs = inputs
        .map { |input| self.class.send(:reference, **input) }
        .to_a

      misses = []

      values = cache.fetch_multi(refs) do |ref|
        misses << ref
        nil
      end

      return values if misses.empty?

      computed = compute_many(misses.map(&:input)).map do |result|
        output.validate(result)
      end

      cache.write_multi(misses.zip(computed).to_h)

      index = 0

      values.map do |value|
        if value.nil?
          computed[index].tap { index += 1 }
        else
          value
        end
      end
    end

    # @return [Output] the value's output schema
    def output
      @output ||= self.class.config.output
    end
  end
end
