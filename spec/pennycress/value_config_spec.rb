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

    it "reflects assigned inputs" do
      inputs = config.inputs

      inputs.model_ids = %i[user post]
      inputs.named = { id: Integer, name: String }

      expect(inputs.model_ids).to eq(%i[post user])
      expect(inputs.named).to eq({ id: Integer, name: String })
    end
  end
end
