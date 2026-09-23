# frozen_string_literal: true

require "active_record"
require "pennycress/errors"
require "pennycress/schema"

RSpec.describe Pennycress::Schema do
  describe ".validate_shape" do
    let(:user_class) { Class.new(ActiveRecord::Base) }
    let(:post_class) { Class.new(ActiveRecord::Base) }
    let(:shape) { { id: Integer, name: String, post: post_class, user: user_class } }

    before do
      stub_const("User", user_class)
      stub_const("Post", post_class)
    end

    it "returns values that conform to the shape" do
      value = {
        id: 1,
        name: "Alice",
        post: post_class.allocate,
        user: user_class.allocate
      }

      expect(described_class.validate_shape(shape, value)).to eq(value)
    end

    it "raises when keys are missing" do
      value = { name: "Alice", post: post_class.allocate }

      expect { described_class.validate_shape(shape, value) }.to raise_error(
        Pennycress::ValidationError,
        "missing key: id\nmissing key: user"
      )
    end

    it "raises when values have incorrect types" do
      value = {
        id: "@id",
        name: "Alice",
        post: post_class.allocate,
        user: :invalid
      }

      expect { described_class.validate_shape(shape, value) }.to raise_error(
        Pennycress::ValidationError,
        %(id is not an instance of Integer: "@id"\nuser is not an instance of User: :invalid)
      )
    end

    it "raises when an extra key is present" do
      value = {
        extra: true,
        id: 1,
        name: "Alice",
        post: post_class.allocate,
        user: user_class.allocate
      }

      expect { described_class.validate_shape(shape, value) }.to raise_error(
        Pennycress::ValidationError,
        "unknown key: extra"
      )
    end

    it "raises when the value is not a hash" do
      expect { described_class.validate_shape(shape, "@string") }.to raise_error(
        Pennycress::ValidationError,
        'value is not a hash: "@string"'
      )
    end
  end

  describe ".validate_type" do
    it "returns values that match the type" do
      expect(described_class.validate_type(Integer, 1)).to eq(1)
    end

    it "raises when a value does not match the type" do
      expect { described_class.validate_type(Integer, "1") }.to raise_error(
        Pennycress::ValidationError,
        'value is not an instance of Integer: "1"'
      )
    end
  end
end
