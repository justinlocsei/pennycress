# frozen_string_literal: true

require "active_record"
require "pennycress/output_reference"

RSpec.describe Pennycress::OutputReference do
  let(:reference) do
    described_class.new(input: { id: 42, user: user })
  end

  let(:post_class) { Class.new(ActiveRecord::Base) }
  let(:user_class) { Class.new(ActiveRecord::Base) }

  let(:user) do
    user_class.allocate.tap do |record|
      allow(record).to receive(:id).and_return(7)
    end
  end

  before do
    stub_const("User", user_class)
    stub_const("Post", post_class)
  end

  describe "#cache_key" do
    it "builds a key from the input" do
      expect(reference.cache_key).to eq("42/7")
    end

    it "returns a stable value" do
      expect(reference.cache_key).to equal(reference.cache_key)
    end

    it "serializes model references by primary key" do
      ref = described_class.new(
        input: {
          discussion: Pennycress::ModelReference.new(
            model_class: user_class,
            id: 9
          )
        }
      )

      expect(ref.cache_key).to eq("9")
    end

    it "uses composite primary keys from a model reference" do
      ref = described_class.new(
        input: {
          order_line: Pennycress::ModelReference.new(
            model_class: user_class,
            id: [3, "XYZ"]
          )
        }
      )

      expect(ref.cache_key).to eq("3/xyz")
    end

    it "serializes input keys in sorted order" do
      user = user_class.allocate
      post = post_class.allocate

      allow(user).to receive(:id).and_return(7)
      allow(post).to receive(:id).and_return(42)

      ref = described_class.new(
        input: { id: 1, name: "Alice", post: post, user: user }
      )

      expect(ref.cache_key).to eq("1/alice/42/7")
    end

    it "omits nil values" do
      ref = described_class.new(input: { id: 42, label: nil })

      expect(ref.cache_key).to eq("42")
    end

    it "includes a namespace when provided" do
      ref = described_class.new(input: { id: 42 }, namespace: "ns")

      expect(ref.cache_key).to eq("ns/42")
    end
  end

  describe "#compute_input" do
    it "resolves model references to instances" do
      ref = described_class.new(
        input: {
          discussion: Pennycress::ModelReference.new(
            model_class: user_class,
            id: 7,
            record: user
          ),
          id: 42
        }
      )

      expect(ref.compute_input).to eq({ discussion: user, id: 42 })
    end
  end

  describe "#input" do
    it "returns the validated input" do
      expect(reference.input).to eq({ id: 42, user: user })
    end
  end
end
