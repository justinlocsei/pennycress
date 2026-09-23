# frozen_string_literal: true

require "pennycress/errors"
require "pennycress/output"

RSpec.describe Pennycress::Output do
  describe "#validate" do
    it "validates a scalar type" do
      output = described_class.new(Integer)

      expect(output.validate(1)).to eq(1)
    end

    it "raises when a scalar result is invalid" do
      output = described_class.new(Integer)

      expect { output.validate("1") }.to raise_error(
        Pennycress::ValidationError,
        'value is not an instance of Integer: "1"'
      )
    end

    it "validates a shaped result" do
      output = described_class.new(count: Integer, label: String)
      result = { count: 1, label: "Alice" }

      expect(output.validate(result)).to eq(result)
    end

    it "raises when a shaped result is invalid" do
      output = described_class.new(count: Integer, label: String)

      expect { output.validate(count: "1", label: "Alice") }.to raise_error(
        Pennycress::ValidationError,
        'count is not an instance of Integer: "1"'
      )
    end
  end
end
