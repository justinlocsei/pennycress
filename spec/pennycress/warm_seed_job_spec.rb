# frozen_string_literal: true

require "pennycress/warm_seed_job"
require "pennycress/value"

RSpec.describe Pennycress::WarmSeedJob do
  it "warms a seed for the given value class" do
    computed = []

    value = Class.new(Pennycress::Value) do
      input id: Integer
      output Integer

      define_method(:compute) do |id:|
        computed << id
        id * 2
      end

      def seed_to_inputs(seed)
        [{ id: seed }, { id: seed + 10 }]
      end
    end

    stub_const("WarmSeedJobSpecValue", value)

    with_memory_cache do
      described_class.perform_now("WarmSeedJobSpecValue", 3)
    end

    expect(computed).to eq([3, 13])
  end
end
