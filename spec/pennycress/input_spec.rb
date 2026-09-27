# frozen_string_literal: true

require "active_record"
require "pennycress/errors"
require "pennycress/input"

RSpec.describe Pennycress::Input do
  describe ".new" do
    it "raises when a named field reuses a model ID" do
      expect do
        Pennycress::Input.new(model_ids: [:channel], named: { channel: String })
      end.to raise_error(ArgumentError, "named fields cannot reuse model IDs: :channel")
    end
  end

  describe "#empty?" do
    it "is true when there are no models or named fields" do
      expect(Pennycress::Input.new).to be_empty
    end

    it "is false when models are defined" do
      input = Pennycress::Input.new(model_ids: [:user])

      expect(input).not_to be_empty
    end

    it "is false when named fields are defined" do
      input = Pennycress::Input.new(named: { id: Integer })

      expect(input).not_to be_empty
    end
  end

  describe "#model_ids" do
    it "is empty by default" do
      expect(Pennycress::Input.new.model_ids).to eq([])
    end

    it "reflects model IDs passed to the constructor" do
      input = Pennycress::Input.new(model_ids: %i[user post])

      expect(input.model_ids).to eq(%i[post user])
    end

    it "exposes unique model IDs" do
      input = Pennycress::Input.new(model_ids: %i[user post user])

      expect(input.model_ids).to eq(%i[post user])
    end
  end

  describe "#named" do
    it "is empty by default" do
      expect(Pennycress::Input.new.named).to eq({})
    end

    it "reflects named fields passed to the constructor" do
      input = Pennycress::Input.new(named: { id: Integer, name: String })

      expect(input.named).to eq({ id: Integer, name: String })
    end
  end

  describe "#validate" do
    let(:user_class) { Class.new(ActiveRecord::Base) }
    let(:post_class) { Class.new(ActiveRecord::Base) }

    let(:input) do
      Pennycress::Input.new(
        model_ids: %i[post user],
        named: { id: Integer, name: String }
      )
    end

    before do
      stub_const("User", user_class)
      stub_const("Post", post_class)
    end

    it "returns an input that conforms to the contract" do
      post = post_class.allocate
      user = user_class.allocate

      allow(post).to receive_messages(id: 1, new_record?: false)
      allow(user).to receive_messages(id: 2, new_record?: false)

      value = {
        id: 1,
        name: "Alice",
        post: post,
        user: user
      }

      validated = input.validate(value)

      expect(validated[:id]).to eq(1)
      expect(validated[:name]).to eq("Alice")
      expect(validated[:post]).to have_attributes(model_class: post_class, id: 1)
      expect(validated[:post].record).to equal(post)
      expect(validated[:user]).to have_attributes(model_class: user_class, id: 2)
      expect(validated[:user].record).to equal(user)
    end

    it "accepts primary key values for model inputs" do
      value = {
        id: 1,
        name: "Alice",
        post: 3,
        user: 4
      }

      validated = input.validate(value)

      expect(validated[:post]).to have_attributes(model_class: post_class, id: 3)
      expect(validated[:user]).to have_attributes(model_class: user_class, id: 4)
    end

    it "raises when an unknown key is present" do
      value = {
        extra: true,
        id: 1,
        name: "Alice",
        post: 3,
        user: 4
      }

      expect { input.validate(value) }.to raise_error(
        Pennycress::ValidationError,
        "unknown key: extra"
      )
    end

    it "raises when the input is not a hash" do
      expect { input.validate("@input") }.to raise_error(
        Pennycress::ValidationError,
        'value is not a hash: "@input"'
      )
    end

    it "raises when an input is incomplete or invalid" do
      value = {
        id: "@id",
        name: "Alice",
        post: post_class.allocate
      }

      expect { input.validate(value) }.to raise_error(
        Pennycress::ValidationError,
        %(id is not an instance of Integer: "@id"\nmissing key: user\npost must be persisted)
      )
    end
  end
end
