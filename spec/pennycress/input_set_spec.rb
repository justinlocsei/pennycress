# frozen_string_literal: true

require "active_record"
require "pennycress/input_set"

RSpec.describe Pennycress::InputSet do
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
      args = {
        id: 1,
        name: "Alice",
        post: post_class.allocate,
        user: user_class.allocate
      }

      expect(inputs.validate(args)).to eq(args)
    end

    it "raises when a model ID or named input are missing" do
      args = { name: "Alice", post: post_class.allocate }

      expect { inputs.validate(args) }.to raise_error(
        Pennycress::ValidationError,
        "missing input: id\nmissing input: user"
      )
    end

    it "raises when a model ID or named input have incorrect types" do
      args = {
        id: "@id",
        name: "Alice",
        post: post_class.allocate,
        user: :invalid
      }

      expect { inputs.validate(args) }.to raise_error(
        Pennycress::ValidationError,
        %(id must be an instance of Integer: "@id"\nuser must be an instance of User: :invalid)
      )
    end

    it "raises when an extra key is present" do
      args = {
        extra: true,
        id: 1,
        name: "Alice",
        post: post_class.allocate,
        user: user_class.allocate
      }

      expect { inputs.validate(args) }.to raise_error(
        Pennycress::ValidationError,
        "unknown input: extra"
      )
    end
  end
end
