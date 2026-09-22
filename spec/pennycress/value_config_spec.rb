# frozen_string_literal: true

require "pennycress/value_config"

RSpec.describe Pennycress::ValueConfig do
  let(:config) { Pennycress::ValueConfig.new }

  describe "#inputs" do
    it "is empty by default" do
      inputs = config.inputs

      expect(inputs.model_ids).to be_empty
      expect(inputs.named).to be_empty
    end

    it "can be configured" do
      config.inputs = Pennycress::InputSet.new(
        model_ids: %i[user post],
        named: { id: Integer, name: String }
      )

      expect(config.inputs.model_ids).to eq(%i[post user])
      expect(config.inputs.named).to eq({ id: Integer, name: String })
    end
  end
end
