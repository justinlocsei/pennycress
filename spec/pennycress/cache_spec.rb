# frozen_string_literal: true

require "active_support/cache"
require "pennycress/cache"
require "pennycress/output_reference"

RSpec.describe Pennycress::Cache do
  let(:store) { ActiveSupport::Cache::MemoryStore.new }
  let(:cache) { described_class.new(store) }

  let(:ref) { Pennycress::OutputReference.new(input: { id: 1 }) }
  let(:other_ref) { Pennycress::OutputReference.new(input: { id: 2 }) }

  describe "#evict" do
    it "evicts a cached value" do
      cache.write(ref, "alfa")

      cache.evict(ref)

      expect(store.read(ref.cache_key)).to be_nil
    end
  end

  describe "#evict_many" do
    it "evicts cached values" do
      cache.write_multi(
        ref => "alfa",
        other_ref => "bravo"
      )

      cache.evict_many([ref, other_ref])

      expect(store.read(ref.cache_key)).to be_nil
      expect(store.read(other_ref.cache_key)).to be_nil
    end
  end

  describe "#fetch" do
    it "returns a cached value when present" do
      cache.write(ref, "alfa")

      expect(cache.fetch(ref) { "bravo" }).to eq("alfa")
    end

    it "computes, caches, and returns a value when absent" do
      result = cache.fetch(ref) { "alfa" }

      expect(result).to eq("alfa")
      expect(store.read(ref.cache_key)).to eq("alfa")
    end
  end

  describe "#fetch_multi" do
    it "returns values in reference order" do
      results = cache.fetch_multi([other_ref, ref]) do |reference|
        reference.input[:id]
      end

      expect(results).to eq([2, 1])
    end

    it "computes only uncached references" do
      cache.write(ref, "alfa")
      computed = []

      results = cache.fetch_multi([ref, other_ref]) do |reference|
        computed << reference
        reference.input[:id]
      end

      expect(results).to eq(["alfa", 2])
      expect(computed).to eq([other_ref])
    end

    it "returns an empty array for no references" do
      expect(cache.fetch_multi([]) { "alfa" }).to eq([])
    end
  end

  describe "#write" do
    it "stores a value in the cache" do
      expect(store.read(ref.cache_key)).to be_nil

      cache.write(ref, "alfa")

      expect(store.read(ref.cache_key)).to eq("alfa")
    end
  end

  describe "#write_multi" do
    it "stores multiple values in the cache" do
      cache.write_multi(
        ref => "alfa",
        other_ref => "bravo"
      )

      expect(store.read(ref.cache_key)).to eq("alfa")
      expect(store.read(other_ref.cache_key)).to eq("bravo")
    end
  end
end
