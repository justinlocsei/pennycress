# frozen_string_literal: true

require "pennycress/errors"
require "pennycress/value"

RSpec.describe Pennycress::Value do
  describe ".derived_from" do
    it "supports model IDs" do
      Class.new(Pennycress::Value) do
        derived_from :uploaded_file, :user
      end
    end

    it "supports model IDs and named inputs" do
      Class.new(Pennycress::Value) do
        derived_from :uploaded_file, :user, name: String
      end
    end

    it "supports only named inputs" do
      Class.new(Pennycress::Value) do
        derived_from name: String
      end
    end
  end

  describe ".fetch" do
    let(:doubled_value) do
      Class.new(Pennycress::Value) do
        derived_from id: Integer

        def derive(id:)
          id * 2
        end
      end
    end

    it "raises when derive is not implemented" do
      value_class = Class.new(Pennycress::Value) do
        derived_from id: Integer
      end

      expect { value_class.fetch(id: 1) }.to raise_error(NotImplementedError)
    end

    it "raises when inputs are invalid" do
      expect { doubled_value.fetch(id: "100") }.to raise_error(
        Pennycress::ValidationError,
        /100/
      )
    end

    it "returns derive results for valid inputs" do
      expect(doubled_value.fetch(id: 3)).to eq(6)
      expect(doubled_value.fetch(id: 5)).to eq(10)
    end
  end
end
