# frozen_string_literal: true

require "pennycress/errors"
require "pennycress/value_config"

RSpec.describe Pennycress::ValueConfig do
  let(:config) { Pennycress::ValueConfig.new }

  describe "#input" do
    it "raises when input is not defined" do
      expect { config.input }.to raise_error(
        Pennycress::ValidationError,
        "input is not defined"
      )
    end

    it "raises when input is empty" do
      config.input = Pennycress::Input.new

      expect { config.input }.to raise_error(
        Pennycress::ValidationError,
        "input is empty"
      )
    end

    it "returns configured input" do
      config.input = Pennycress::Input.new(
        model_ids: %i[user post],
        named: { id: Integer, name: String }
      )

      expect(config.input.model_ids).to eq(%i[post user])
      expect(config.input.named).to eq({ id: Integer, name: String })
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
    it "returns an empty array by default" do
      expect(config.seeds.call).to eq([])
    end

    it "returns configured seeds" do
      seeds = [1, 2, 3]
      config.seeds = proc { seeds }

      expect(config.seeds.call).to eq(seeds)
    end
  end
end
