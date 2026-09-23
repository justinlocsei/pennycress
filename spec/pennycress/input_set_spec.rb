# frozen_string_literal: true

require "active_record"
require "pennycress/errors"
require "pennycress/input_set"

RSpec.describe Pennycress::InputSet do
  describe "#empty?" do
    it "is true when there are no models or named inputs" do
      expect(Pennycress::InputSet.new).to be_empty
    end

    it "is false when models are defined" do
      inputs = Pennycress::InputSet.new(model_ids: [:user])

      expect(inputs).not_to be_empty
    end

    it "is false when named inputs are defined" do
      inputs = Pennycress::InputSet.new(named: { id: Integer })

      expect(inputs).not_to be_empty
    end
  end

  describe "#model_ids" do
    it "is empty by default" do
      expect(Pennycress::InputSet.new.model_ids).to eq([])
    end

    it "reflects model inputs passed to the constructor" do
      inputs = Pennycress::InputSet.new(model_ids: %i[user post])

      expect(inputs.model_ids).to eq(%i[post user])
    end

    it "exposes unique model IDs" do
      inputs = Pennycress::InputSet.new(model_ids: %i[user post user])

      expect(inputs.model_ids).to eq(%i[post user])
    end
  end

  describe "#named" do
    it "is empty by default" do
      expect(Pennycress::InputSet.new.named).to eq({})
    end

    it "reflects named inputs passed to the constructor" do
      inputs = Pennycress::InputSet.new(named: { id: Integer, name: String })

      expect(inputs.named).to eq({ id: Integer, name: String })
    end
  end

  describe "#validate" do
    let(:user_class) { Class.new(ActiveRecord::Base) }
    let(:post_class) { Class.new(ActiveRecord::Base) }

    let(:inputs) do
      Pennycress::InputSet.new(
        model_ids: %i[post user],
        named: { id: Integer, name: String }
      )
    end

    before do
      stub_const("User", user_class)
      stub_const("Post", post_class)
    end

    it "returns inputs that conform to the schema" do
      value = {
        id: 1,
        name: "Alice",
        post: post_class.allocate,
        user: user_class.allocate
      }

      expect(inputs.validate(value)).to eq(value)
    end

    it "raises when inputs are incomplete or invalid" do
      value = {
        id: "@id",
        name: "Alice",
        post: post_class.allocate
      }

      expect { inputs.validate(value) }.to raise_error(
        Pennycress::ValidationError,
        %(id is not an instance of Integer: "@id"\nmissing key: user)
      )
    end
  end
end
