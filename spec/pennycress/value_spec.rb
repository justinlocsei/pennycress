# frozen_string_literal: true

require "pennycress/errors"
require "pennycress/value"

RSpec.describe Pennycress::Value do
  describe ".inputs" do
    it "supports model IDs" do
      Class.new(Pennycress::Value) do
        inputs :uploaded_file, :user
      end
    end

    it "supports model IDs and named inputs" do
      Class.new(Pennycress::Value) do
        inputs :uploaded_file, :user, name: String
      end
    end

    it "supports only named inputs" do
      Class.new(Pennycress::Value) do
        inputs name: String
      end
    end
  end

  describe ".fetch" do
    let(:doubled_value) do
      Class.new(Pennycress::Value) do
        inputs id: Integer
        output Integer

        def compute(id:)
          id * 2
        end
      end
    end

    it "raises when compute is not implemented" do
      value_class = Class.new(Pennycress::Value) do
        inputs id: Integer
      end

      expect { value_class.fetch(id: 1) }.to raise_error(NotImplementedError)
    end

    it "raises when inputs are invalid" do
      expect { doubled_value.fetch(id: "100") }.to raise_error(
        Pennycress::ValidationError,
        /100/
      )
    end

    it "returns compute results for valid inputs" do
      expect(doubled_value.fetch(id: 3)).to eq(6)
      expect(doubled_value.fetch(id: 5)).to eq(10)
    end

    it "raises when the computed output is invalid" do
      invalid_output = Class.new(Pennycress::Value) do
        inputs id: Integer
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
end
