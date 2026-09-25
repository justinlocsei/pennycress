# frozen_string_literal: true

require "active_support/cache"
require "pennycress/configuration"

RSpec.describe Pennycress::Configuration do
  describe ".build" do
    it "returns a new configuration" do
      config = described_class.build { |_| }

      expect(config).to be_a(described_class)
      expect(config).not_to equal(described_class.current)
    end

    it "yields a configuration instance" do
      described_class.build do |config|
        expect(config).to be_a(described_class)
      end
    end

    it "returns the configuration with the settings applied in the block" do
      config = described_class.build do |c|
        c.cache_namespace = "pennycress/test"
      end

      expect(config.cache_namespace).to eq("pennycress/test")
    end
  end

  describe ".current" do
    it "returns a configuration" do
      expect(described_class.current).to be_a(described_class)
    end

    it "is stable across invocations" do
      expect(described_class.current).to equal(described_class.current)
    end
  end

  describe ".modify" do
    it "returns a copy of the current configuration" do
      described_class.override(
        described_class.build { |config| config.cache_namespace = "pennycress/original" }
      ) do
        current = described_class.current
        config = described_class.modify { |_| }

        expect(config).to be_a(described_class)
        expect(config).not_to equal(current)
        expect(config.cache_namespace).to eq("pennycress/original")
      end
    end

    it "returns the modified configuration" do
      config = described_class.modify do |built|
        built.cache_namespace = "pennycress/test"
      end

      expect(config.cache_namespace).to eq("pennycress/test")
    end

    it "does not modify the current configuration" do
      described_class.override(
        described_class.build { |config| config.cache_namespace = "pennycress/original" }
      ) do
        described_class.modify do |built|
          built.cache_namespace = "pennycress/test"
        end

        expect(described_class.current.cache_namespace).to eq("pennycress/original")
      end
    end

    it "copies the current cache store" do
      store = ActiveSupport::Cache::MemoryStore.new

      described_class.override(
        described_class.build { |config| config.cache = store }
      ) do
        config = described_class.modify { |_| }

        expect(config.cache).to equal(store)
      end
    end
  end

  describe ".override" do
    it "uses the given configuration within the block" do
      custom = described_class.new

      described_class.override(custom) do
        expect(described_class.current).to equal(custom)
      end
    end

    it "restores the previous configuration afterward" do
      original = described_class.current
      custom = described_class.new

      described_class.override(custom) do
        expect(described_class.current).to_not equal(original)
      end

      expect(described_class.current).to equal(original)
    end

    it "restores the previous configuration when the block raises" do
      original = described_class.current
      custom = described_class.new

      expect {
        described_class.override(custom) do
          raise "error"
        end
      }.to raise_error("error")

      expect(described_class.current).to equal(original)
    end

    it "returns the block result" do
      result = described_class.override(described_class.new) do
        "done"
      end

      expect(result).to eq("done")
    end
  end

  describe "#cache" do
    it "uses a default store" do
      expect(described_class.new.cache).to be_a(ActiveSupport::Cache::Store)
    end

    it "returns the configured store" do
      config = described_class.new

      store = ActiveSupport::Cache::MemoryStore.new
      config.cache = store

      expect(config.cache).to equal(store)
    end
  end

  describe "#cache_namespace" do
    it "has a default value" do
      expect(described_class.new.cache_namespace).to_not be_empty
    end
  end
end
