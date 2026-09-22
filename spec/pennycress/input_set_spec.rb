# frozen_string_literal: true

require "active_record"
require "pennycress/input_set"

RSpec.describe Pennycress::InputSet do
  let(:inputs) { Pennycress::InputSet.new }

  describe "#model_ids" do
    it "is empty by default" do
      expect(inputs.model_ids).to eq([])
    end

    it "reflects assigned model inputs" do
      inputs.model_ids = %i[user post]
      expect(inputs.model_ids).to eq(%i[post user])
    end

    it "exposes unique model IDs" do
      inputs.model_ids = %i[user post user]
      expect(inputs.model_ids).to eq(%i[post user])
    end

    it "is refreshed when new models are assigned" do
      inputs.model_ids = [:user]
      expect(inputs.model_ids).to eq([:user])

      inputs.model_ids = [:post]
      expect(inputs.model_ids).to eq([:post])
    end
  end

  describe "#named" do
    it "is empty by default" do
      expect(inputs.named).to eq({})
    end

    it "reflects assigned named inputs" do
      inputs.named = { id: Integer, name: String }
      expect(inputs.named).to eq({ id: Integer, name: String })
    end

    it "is refreshed when new named inputs are assigned" do
      inputs.named = { id: Integer }
      expect(inputs.named).to eq({ id: Integer })

      inputs.named = { name: String }
      expect(inputs.named).to eq({ name: String })
    end
  end

  describe "#validate" do
    let(:user_class) { Class.new(ActiveRecord::Base) }
    let(:post_class) { Class.new(ActiveRecord::Base) }

    before do
      stub_const("User", user_class)
      stub_const("Post", post_class)

      inputs.model_ids = %i[user post]
      inputs.named = { id: Integer, name: String }
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
