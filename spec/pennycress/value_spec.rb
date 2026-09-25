# frozen_string_literal: true

require "pennycress/errors"
require "pennycress/value"
require "pennycress/value_config"

RSpec.describe Pennycress::Value do
  describe ".config" do
    it "returns the value's configuration" do
      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer
      end

      expect(value.config).to be_a(Pennycress::ValueConfig)
    end
  end

  describe ".fetch" do
    let(:doubled_value) do
      Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id * 2
        end
      end
    end

    it "raises when compute is not implemented" do
      value_class = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer
      end

      expect { value_class.fetch(id: 1) }.to raise_error(NotImplementedError)
    end

    it "raises when input is invalid" do
      expect { doubled_value.fetch(id: "100") }.to raise_error(
        Pennycress::ValidationError,
        /100/
      )
    end

    it "returns compute results for valid input" do
      expect(doubled_value.fetch(id: 3)).to eq(6)
      expect(doubled_value.fetch(id: 5)).to eq(10)
    end

    it "raises when the computed output is invalid" do
      invalid_output = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id.to_s
        end
      end

      expect { invalid_output.fetch(id: 1) }.to raise_error(
        Pennycress::ValidationError,
        'value is not an instance of Integer: "1"'
      )
    end

    it "uses the configuration namespace for anonymous value classes" do
      value_class = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id * 2
        end
      end

      value_class.fetch(
        id: 3,
        inspect_reference: ->(ref) { expect(ref.cache_key).to eq("pennycress/3") }
      )
    end

    it "includes a multi-level constant path in the cache key" do
      value_class = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id * 2
        end
      end

      stub_const("Alfa::Bravo", value_class)

      value_class.fetch(
        id: 3,
        inspect_reference: lambda { |ref|
          expect(ref.cache_key).to eq("pennycress/alfa/bravo/3")
        }
      )
    end

    it "uses the global cache namespace in the cache key" do
      value_class = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id * 2
        end
      end

      stub_const("Alfa", value_class)

      with_cache_namespace("pennycress/test") do
        value_class.fetch(
          id: 3,
          inspect_reference: ->(ref) { expect(ref.cache_key).to eq("pennycress/test/alfa/3") }
        )
      end
    end

    context "with a memory cache" do
      around do |example|
        with_memory_cache { example.run }
      end

      it "returns a cached result without recomputing" do
        compute_calls = 0

        value_class = Class.new(Pennycress::Value) do
          input id: Integer
          output Integer

          define_method(:compute) do |id:|
            compute_calls += 1
            id * 2
          end
        end

        expect(value_class.fetch(id: 3)).to eq(6)
        expect(value_class.fetch(id: 3)).to eq(6)
        expect(compute_calls).to eq(1)
      end

      it "caches each input separately" do
        compute_calls = 0

        value_class = Class.new(Pennycress::Value) do
          input id: Integer
          output Integer

          define_method(:compute) do |id:|
            compute_calls += 1
            id * 2
          end
        end

        expect(value_class.fetch(id: 3)).to eq(6)
        expect(value_class.fetch(id: 5)).to eq(10)
        expect(value_class.fetch(id: 3)).to eq(6)

        expect(compute_calls).to eq(2)
      end
    end
  end

  describe ".fetch_many" do
    let(:doubled_value) do
      Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id * 2
        end
      end
    end

    it "computes an output for each input" do
      expect(doubled_value.fetch_many([{ id: 3 }, { id: 5 }])).to eq([6, 10])
    end

    it "returns an array" do
      expect(doubled_value.fetch_many([{ id: 3 }])).to be_a(Array)
    end

    it "pulls inputs on demand through the pipeline" do
      computed = []
      pulled = []

      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        define_method(:compute) do |id:|
          computed << id
          id * 2
        end
      end

      enum = Enumerator.new do |yielder|
        pulled << :first
        yielder << { id: 3 }
        pulled << :second
        yielder << { id: 5 }
      end

      expect(pulled).to eq([])
      expect(computed).to eq([])

      expect(value.fetch_many(enum)).to eq([6, 10])

      expect(pulled).to eq(%i[first second])
      expect(computed).to eq([3, 5])
    end

    it "stops at the first invalid input without processing the rest" do
      computed = []

      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        define_method(:compute) do |id:|
          computed << id
          id * 2
        end
      end

      enum = Enumerator.new do |yielder|
        yielder << { id: 3 }
        yielder << { id: "5" }
        yielder << { id: 7 }
      end

      expect { value.fetch_many(enum) }.to raise_error(
        Pennycress::ValidationError,
        /5/
      )

      expect(computed).to be_empty
    end

    it "raises when an input is invalid" do
      expect { doubled_value.fetch_many([{ id: 3 }, { id: "5" }]) }.to raise_error(
        Pennycress::ValidationError,
        /5/
      )
    end

    it "raises when any computed outputs are invalid" do
      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id == 1 ? id.to_s : id * 2
        end
      end

      expect { value.fetch_many([{ id: 1 }, { id: 2 }]) }.to raise_error(
        Pennycress::ValidationError,
        'value is not an instance of Integer: "1"'
      )
    end

    it "can use a custom compute_many implementation" do
      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id * 2
        end

        def compute_many(inputs)
          inputs.map { |input| compute(**input) * 2 }
        end
      end

      expect(value.fetch_many([{ id: 3 }, { id: 5 }])).to eq([12, 20])
    end

    it "raises when a custom compute_many returns an invalid output" do
      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id * 2
        end

        def compute_many(inputs)
          inputs.map { |input| compute(**input).to_s }
        end
      end

      expect { value.fetch_many([{ id: 3 }, { id: 5 }]) }.to raise_error(
        Pennycress::ValidationError,
        'value is not an instance of Integer: "6"'
      )
    end

    context "with a memory cache" do
      around do |example|
        with_memory_cache { example.run }
      end

      it "returns cached results without recomputing" do
        compute_calls = 0

        value_class = Class.new(Pennycress::Value) do
          input id: Integer
          output Integer

          define_method(:compute) do |id:|
            compute_calls += 1
            id * 2
          end
        end

        expect(value_class.fetch_many([{ id: 3 }, { id: 5 }])).to eq([6, 10])
        expect(value_class.fetch_many([{ id: 3 }, { id: 5 }, { id: 7 }])).to eq([6, 10, 14])

        expect(compute_calls).to eq(3)
      end
    end
  end

  describe ".input" do
    it "supports model IDs" do
      Class.new(Pennycress::Value) do
        input :uploaded_file, :user
      end
    end

    it "supports model IDs and named fields" do
      Class.new(Pennycress::Value) do
        input :uploaded_file, :user, name: String
      end
    end

    it "supports only named fields" do
      Class.new(Pennycress::Value) do
        input name: String
      end
    end

    it "raises when a named field reuses a model ID" do
      expect {
        Class.new(Pennycress::Value) do
          input :channel, channel: String
        end
      }.to raise_error(ArgumentError, "named fields cannot reuse model IDs: :channel")
    end
  end

  describe ".seeds" do
    it "defines and returns seeds" do
      value = Class.new(Pennycress::Value) do
        seeds { [1, 2, 3] }
      end

      expect(value.seeds).to eq([1, 2, 3])
    end

    it "evaluates the block in the class context" do
      value = Class.new(Pennycress::Value) do
        def self.seed_ids
          [4, 5, 6]
        end

        seeds { seed_ids }
      end

      expect(value.seeds).to eq([4, 5, 6])
    end

    it "returns an empty array by default" do
      value = Class.new(Pennycress::Value)

      expect(value.seeds).to eq([])
    end
  end

  describe ".watch" do
    it "registers a watch on the config" do
      value = Class.new(Pennycress::Value) do
        watch :discussion do |discussion|
          [{ id: discussion }]
        end
      end

      watches = value.config.watches

      expect(watches.length).to eq(1)
      expect(watches.first.id).to eq(:discussion)
      expect(watches.first.inputs_for(1)).to eq([{ id: 1 }])
    end

    it "supports multiple watches" do
      value = Class.new(Pennycress::Value) do
        watch :discussion do |discussion|
          [{ id: discussion }]
        end

        watch :comment do |comment|
          [{ id: comment }]
        end
      end

      expect(value.config.watches.map(&:id)).to eq(%i[discussion comment])
    end
  end

  describe ".warm" do
    it "does nothing when seeds are empty" do
      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer
      end

      expect { value.warm }.not_to raise_error
    end

    it "warms each seed" do
      computed = []

      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        seeds { [1, 2] }

        define_method(:compute) do |id:|
          computed << id
          id * 2
        end

        def seed_to_inputs(seed)
          [{ id: seed }, { id: seed + 10 }]
        end
      end

      value.warm

      expect(computed).to eq([1, 11, 2, 12])
    end

    it "raises when seed_to_inputs is not implemented" do
      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        seeds { [1] }

        def compute(id:)
          id
        end
      end

      expect { value.warm }.to raise_error(NotImplementedError)
    end
  end

  describe "#seed_to_inputs" do
    it "raises when not implemented" do
      value = Class.new(Pennycress::Value) do
        seeds { [1] }
      end

      expect { value.new.seed_to_inputs(1) }.to raise_error(NotImplementedError)
    end

    it "returns input hashes for a seed" do
      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        seeds { [1, 2] }

        def seed_to_inputs(seed)
          [{ id: seed }, { id: seed + 10 }]
        end
      end

      expect(value.new.seed_to_inputs(1)).to eq([{ id: 1 }, { id: 11 }])
    end
  end

  describe "#warm_seed" do
    it "fetches each input produced by seed_to_inputs" do
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

      value.new.warm_seed(3)

      expect(computed).to eq([3, 13])
    end

    it "raises when seed_to_inputs is not implemented" do
      value = Class.new(Pennycress::Value) do
        input id: Integer
        output Integer

        def compute(id:)
          id
        end
      end

      expect { value.new.warm_seed(1) }.to raise_error(NotImplementedError)
    end
  end
end
