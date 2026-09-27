# frozen_string_literal: true

require "pennycress/caching"

RSpec.describe Pennycress::Caching do
  describe ".key" do
    it "joins segments with slashes" do
      expect(described_class.key("alfa", "bravo", 3)).to eq("alfa/bravo/3")
    end

    it "omits nil segments" do
      expect(described_class.key("alfa", nil, "bravo")).to eq("alfa/bravo")
    end

    it "omits empty segments" do
      expect(described_class.key("alfa", "", "bravo")).to eq("alfa/bravo")
    end

    it "returns an empty string when no segments remain" do
      expect(described_class.key(nil, "")).to eq("")
    end
  end
end
