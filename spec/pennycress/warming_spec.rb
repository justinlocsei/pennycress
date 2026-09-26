# frozen_string_literal: true

require "pennycress/value"
require "pennycress/warming"

RSpec.describe Pennycress::Warming do
  describe ".warm_cache" do
    it "warms each seed for each registered value when async is false" do
      computed = []

      alpha = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        seeds { [1] }

        define_method(:compute) do |id:|
          computed << id
          id
        end

        def seed_to_inputs(seed)
          [{ id: seed }]
        end
      end

      bravo = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        seeds { [2, 3] }

        define_method(:compute) do |id:|
          computed << id
          id
        end

        def seed_to_inputs(seed)
          [{ id: seed }]
        end
      end

      stub_const("AlphaValue", alpha)
      stub_const("BravoValue", bravo)

      with_memory_cache do
        described_class.warm_cache(async: false)
      end

      expect(computed).to eq([1, 2, 3])
    end

    it "enqueues a job for each seed when async is true" do
      alpha = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        seeds { [1] }
      end

      bravo = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        seeds { [2, 3] }
      end

      stub_const("AlphaValue", alpha)
      stub_const("BravoValue", bravo)

      allow(Pennycress::WarmSeedJob).to receive(:perform_later)

      described_class.warm_cache(async: true)

      expect(Pennycress::WarmSeedJob).to have_received(:perform_later).with("AlphaValue", 1)
      expect(Pennycress::WarmSeedJob).to have_received(:perform_later).with("BravoValue", 2)
      expect(Pennycress::WarmSeedJob).to have_received(:perform_later).with("BravoValue", 3)
    end

    it "raises when a value class has no name" do
      Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        seeds { [1] }
      end

      expect {
        described_class.warm_cache(async: false)
      }.to raise_error(ArgumentError, "value class must have a name")
    end
  end
end
