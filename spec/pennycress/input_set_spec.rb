# frozen_string_literal: true

require "pennycress/input_set"

RSpec.describe Pennycress::InputSet do
  let(:inputs) { Pennycress::InputSet.new }

  describe "#model_ids" do
    it "is empty by default" do
      expect(inputs.model_ids).to eq([])
    end

    it "reflects assigned model inputs" do
      inputs.model_ids = %i[user post]
      expect(inputs.model_ids).to eq(%i[post user])
    end

    it "exposes unique model IDs" do
      inputs.model_ids = %i[user post user]
      expect(inputs.model_ids).to eq(%i[post user])
    end

    it "is refreshed when new models are assigned" do
      inputs.model_ids = [:user]
      expect(inputs.model_ids).to eq([:user])

      inputs.model_ids = [:post]
      expect(inputs.model_ids).to eq([:post])
    end
  end

  describe "#named" do
    it "is empty by default" do
      expect(inputs.named).to eq({})
    end

    it "reflects assigned named inputs" do
      inputs.named = { id: Integer, name: String }
      expect(inputs.named).to eq({ id: Integer, name: String })
    end

    it "is refreshed when new named inputs are assigned" do
      inputs.named = { id: Integer }
      expect(inputs.named).to eq({ id: Integer })

      inputs.named = { name: String }
      expect(inputs.named).to eq({ name: String })
    end
  end
end
