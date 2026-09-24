# frozen_string_literal: true

require "pennycress/errors"
require "pennycress/value"

RSpec.describe Pennycress::Value do
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

      expect(computed).to eq([3])
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

    it "raises when seeds are not defined" do
      value = Class.new(Pennycress::Value)

      expect { value.seeds }.to raise_error(
        Pennycress::ValidationError,
        "seeds are not defined"
      )
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
end
