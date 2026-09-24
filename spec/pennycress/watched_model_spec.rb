# frozen_string_literal: true

require "pennycress/watched_model"

RSpec.describe Pennycress::WatchedModel do
  describe "#id" do
    it "reflects the model ID passed to the constructor" do
      watched_model = described_class.new(:discussion) { [] }

      expect(watched_model.id).to eq(:discussion)
    end
  end

  describe "#inputs_for" do
    it "returns inputs for the given model" do
      watched_model = described_class.new(:discussion) do |discussion|
        [{ comment: discussion.fetch(:id) }]
      end

      expect(watched_model.inputs_for({ id: 1 })).to eq([{ comment: 1 }])
    end
  end
end
