# frozen_string_literal: true

require "pennycress/registry"
require "pennycress/value"

RSpec.describe Pennycress::Registry do
  describe ".override" do
    it "uses the given registry within the block" do
      custom = described_class.new

      described_class.override(custom) do
        expect(described_class.current).to equal(custom)
      end
    end

    it "restores the previous registry afterward" do
      original = described_class.current
      custom = described_class.new

      described_class.override(custom) {}

      expect(described_class.current).to equal(original)
    end
  end

  describe "#register" do
    it "records value subclasses" do
      value = Class.new(Pennycress::Value)

      expect(described_class.current.values).to include(value)
    end
  end

  describe "#reset" do
    it "clears registered value classes" do
      Class.new(Pennycress::Value)

      described_class.current.reset

      expect(described_class.current.values).to eq([])
    end
  end
end
