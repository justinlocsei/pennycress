# frozen_string_literal: true

require "pennycress/warming"

RSpec.describe Pennycress::Warming do
  describe ".warm_cache" do
    it "warms each seed for each registered value when async is false" do
      alfa = identity_value_class do
        seeds { [1] }

        def seed_to_inputs(seed)
          [{ id: seed }]
        end
      end

      bravo = identity_value_class do
        seeds { [2, 3] }

        def seed_to_inputs(seed)
          [{ id: seed }]
        end
      end

      stub_const("AlfaValue", alfa)
      stub_const("BravoValue", bravo)

      with_memory_cache do
        described_class.warm_cache(async: false)
      end

      expect(alfa.computed_values + bravo.computed_values).to eq([1, 2, 3])
    end

    it "enqueues a job for each seed when async is true" do
      alfa = identity_value_class do
        seeds { [1] }
      end

      bravo = identity_value_class do
        seeds { [2, 3] }
      end

      stub_const("AlfaValue", alfa)
      stub_const("BravoValue", bravo)

      allow(Pennycress::WarmSeedJob).to receive(:perform_later)

      described_class.warm_cache(async: true)

      expect(Pennycress::WarmSeedJob).to have_received(:perform_later).with("AlfaValue", 1)
      expect(Pennycress::WarmSeedJob).to have_received(:perform_later).with("BravoValue", 2)
      expect(Pennycress::WarmSeedJob).to have_received(:perform_later).with("BravoValue", 3)
    end

    it "raises when a value class has no name" do
      identity_value_class do
        seeds { [1] }
      end

      expect {
        described_class.warm_cache(async: false)
      }.to raise_error(ArgumentError, "value class must have a name")
    end
  end
end
