# frozen_string_literal: true

require "pennycress/errors"
require "pennycress/value_config"

RSpec.describe Pennycress::ValueConfig do
  let(:config) { Pennycress::ValueConfig.new }

  describe "#inputs" do
    it "raises when inputs are not defined" do
      expect { config.inputs }.to raise_error(
        Pennycress::ValidationError,
        "inputs are not defined"
      )
    end

    it "raises when inputs are empty" do
      config.inputs = Pennycress::InputSet.new

      expect { config.inputs }.to raise_error(
        Pennycress::ValidationError,
        "inputs are empty"
      )
    end

    it "returns configured inputs" do
      config.inputs = Pennycress::InputSet.new(
        model_ids: %i[user post],
        named: { id: Integer, name: String }
      )

      expect(config.inputs.model_ids).to eq(%i[post user])
      expect(config.inputs.named).to eq({ id: Integer, name: String })
    end
  end

  describe "#output" do
    it "raises when output is not defined" do
      expect { config.output }.to raise_error(
        Pennycress::ValidationError,
        "output is not defined"
      )
    end

    it "returns configured output" do
      config.output = Pennycress::Output.new(Integer)

      expect(config.output.validate(1)).to eq(1)
    end
  end

  describe "#seeds" do
    it "raises when seeds are not defined" do
      expect { config.seeds }.to raise_error(
        Pennycress::ValidationError,
        "seeds are not defined"
      )
    end

    it "returns the lazily evaluated seeds" do
      seeds = [1, 2, 3]
      config.seeds = proc { seeds }

      expect(config.seeds.call).to eq(seeds)
    end
  end
end
