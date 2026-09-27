# frozen_string_literal: true

require "active_record"
require "pennycress/errors"
require "pennycress/model_reference"

RSpec.describe Pennycress::ModelReference do
  let(:discussion_class) { Class.new(ActiveRecord::Base) }

  before do
    stub_const("Discussion", discussion_class)
  end

  def build_record(id: 1)
    discussion_class.allocate.tap do |record|
      allow(record).to receive(:id).and_return(id)
      allow(record).to receive(:new_record?).and_return(false)
    end
  end

  describe ".from" do
    it "accepts a persisted model instance" do
      record = build_record

      reference = described_class.from(discussion_class, record, label: "discussion")

      expect(reference.id).to eq(1)
      expect(reference.record).to equal(record)
    end

    it "accepts a scalar primary key value" do
      reference = described_class.from(discussion_class, 42, label: "discussion")

      expect(reference.id).to eq(42)
    end

    it "accepts string primary key values" do
      reference = described_class.from(discussion_class, "42", label: "discussion")

      expect(reference.id).to eq("42")
    end

    it "raises when an instance is not persisted" do
      record = discussion_class.allocate
      allow(record).to receive(:id).and_return(nil)
      allow(record).to receive(:new_record?).and_return(true)

      expect {
        described_class.from(discussion_class, record, label: "discussion")
      }.to raise_error(Pennycress::ValidationError, "discussion must be persisted")
    end

    it "raises when a scalar primary key value is invalid" do
      expect {
        described_class.from(discussion_class, nil, label: "discussion")
      }.to raise_error(
        Pennycress::ValidationError,
        "discussion must be a Discussion or a primary key value: nil"
      )

      expect {
        described_class.from(discussion_class, {}, label: "discussion")
      }.to raise_error(
        Pennycress::ValidationError,
        "discussion must be a Discussion or a primary key value: {}"
      )
    end

    it "raises when a scalar model receives an array" do
      expect {
        described_class.from(discussion_class, [1], label: "discussion")
      }.to raise_error(
        Pennycress::ValidationError,
        "discussion must be a Discussion or a primary key value: [1]"
      )
    end

    context "with a composite primary key" do
      let(:order_line_class) do
        Class.new(ActiveRecord::Base) do
          def self.composite_primary_key?
            true
          end

          def self.primary_key
            %i[order_id line_number]
          end
        end
      end

      before do
        stub_const("OrderLine", order_line_class)
      end

      it "accepts a composite primary key array" do
        reference = described_class.from(order_line_class, [3, 7], label: "order_line")

        expect(reference.id).to eq([3, 7])
      end

      it "raises when the composite primary key has the wrong length" do
        expect {
          described_class.from(order_line_class, [3], label: "order_line")
        }.to raise_error(
          Pennycress::ValidationError,
          "order_line must have 2 primary key values, got 1"
        )
      end

      it "raises when a composite model receives a scalar" do
        expect {
          described_class.from(order_line_class, 3, label: "order_line")
        }.to raise_error(
          Pennycress::ValidationError,
          "order_line must be a OrderLine or an array of 2 key values"
        )
      end

      it "raises when a composite primary key value is invalid" do
        expect {
          described_class.from(order_line_class, [3, nil], label: "order_line")
        }.to raise_error(
          Pennycress::ValidationError,
          "order_line primary keys must use scalar values"
        )
      end
    end
  end

  describe "#cache_key" do
    it "returns scalar identities as a single segment" do
      reference = described_class.new(model_class: discussion_class, id: 42)

      expect(reference.cache_key).to eq(["42"])
    end

    it "returns one segment per composite primary key value" do
      reference = described_class.new(model_class: discussion_class, id: [3, "XYZ"])

      expect(reference.cache_key).to eq(%w[3 XYZ])
    end
  end

  describe "#record" do
    it "returns a loaded record when one is available" do
      record = build_record

      reference = described_class.new(
        model_class: discussion_class,
        id: 1,
        record: record
      )

      expect(reference.record).to equal(record)
    end

    it "loads the record by primary key when one is not available" do
      record = build_record

      allow(discussion_class).to receive(:find).with(1).and_return(record)

      reference = described_class.new(model_class: discussion_class, id: 1)

      expect(reference.record).to equal(record)
      expect(discussion_class).to have_received(:find).with(1)
    end
  end
end
