# frozen_string_literal: true

require "active_support/cache"
require "pennycress/configuration"
require "pennycress/value"

module Pennycress
  # Helpers for configuring Pennycress in specs.
  module TestHelpers
    # Builds a value class that returns its integer ID input unchanged
    #
    # @yield [Class] an optional class body for extended configuration
    # @return [Class] a value class with additional tracking attributes
    def identity_value_class(&extension)
      item_class = Class.new(ActiveRecord::Base)

      allow(item_class).to receive(:find) do |id|
        item_class.allocate.tap do |record|
          allow(record).to receive_messages(id: id, new_record?: false)
        end
      end

      stub_const("Item", item_class)

      Class.new(Pennycress::Value) do
        class << self
          attr_accessor :compute_calls, :computed_values
        end

        self.compute_calls = 0
        self.computed_values = []

        input :item
        output Integer

        define_method(:compute) do |item:|
          self.class.computed_values << item.id
          self.class.compute_calls += 1

          item.id
        end

        class_eval(&extension) if extension
      end
    end

    # Runs a block with an in-memory cache configuration
    #
    # @param namespace [String] the global cache namespace
    # @yield run examples against the temporary configuration
    # @return [Object] the block's return value
    def with_memory_cache(namespace: "pennycress/test", &block)
      Configuration.override(
        build_memory_cache_config(namespace),
        &block
      )
    end

    # Runs a block with a temporary global cache namespace
    #
    # @param namespace [String] the global cache namespace
    # @yield run examples against the temporary configuration
    # @return [Object] the block's return value
    def with_cache_namespace(namespace, &block)
      config = Configuration.modify do |built|
        built.cache_namespace = namespace
      end

      Configuration.override(config, &block)
    end

  private

    # Builds a configuration backed by an in-memory cache store
    #
    # @param namespace [String] the global cache key prefix
    # @return [Configuration]
    def build_memory_cache_config(namespace)
      Configuration.modify do |config|
        config.cache = ActiveSupport::Cache::MemoryStore.new
        config.cache_namespace = namespace
      end
    end
  end
end
