# frozen_string_literal: true

require "pennycress/warm_seed_job"

RSpec.describe Pennycress::WarmSeedJob do
  it "warms a seed for the given value class" do
    value = identity_value_class do
      def seed_to_inputs(seed)
        [{ item: seed }, { item: seed + 10 }]
      end
    end

    stub_const("WarmSeedJobSpecValue", value)

    with_memory_cache do
      described_class.perform_now("WarmSeedJobSpecValue", 3)
    end

    expect(value.computed_values).to eq([3, 13])
    expect(value.compute_calls).to eq(2)
  end
end
