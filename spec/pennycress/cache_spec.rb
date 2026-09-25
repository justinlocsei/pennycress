# frozen_string_literal: true

require "active_support/cache"
require "pennycress/cache"
require "pennycress/output_reference"

RSpec.describe Pennycress::Cache do
  let(:store) { ActiveSupport::Cache::MemoryStore.new }
  let(:cache) { described_class.new(store) }
  let(:ref) { Pennycress::OutputReference.new(input: { id: 42 }) }

  describe "#delete" do
    it "deletes a cached value" do
      cache.write(ref, 84)

      expect(cache.delete(ref)).to be(true)
      expect(store.read(ref.cache_key)).to be_nil
    end
  end

  describe "#fetch" do
    it "returns a cached value when present" do
      cache.write(ref, 84)

      expect(cache.fetch(ref) { 99 }).to eq(84)
    end

    it "computes, caches, and returns a value when absent" do
      result = cache.fetch(ref) { 84 }

      expect(result).to eq(84)
      expect(store.read(ref.cache_key)).to eq(84)
    end
  end

  describe "#fetch_multi" do
    let(:other_ref) { Pennycress::OutputReference.new(input: { id: 99 }) }

    it "returns values in reference order" do
      results = cache.fetch_multi([other_ref, ref]) do |reference|
        reference.input[:id]
      end

      expect(results).to eq([99, 42])
    end

    it "computes only uncached references" do
      cache.write(ref, 84)
      computed = []

      results = cache.fetch_multi([ref, other_ref]) do |reference|
        computed << reference
        reference.input[:id]
      end

      expect(results).to eq([84, 99])
      expect(computed).to eq([other_ref])
    end

    it "returns an empty array for no references" do
      expect(cache.fetch_multi([]) { 99 }).to eq([])
    end
  end

  describe "#write" do
    it "stores a value in the cache" do
      expect(store.read(ref.cache_key)).to be_nil
      expect(cache.write(ref, 84)).to be(true)
      expect(store.read(ref.cache_key)).to eq(84)
    end
  end
end
