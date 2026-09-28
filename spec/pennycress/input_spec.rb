# frozen_string_literal: true

require "active_record"
require "pennycress/errors"
require "pennycress/input"

RSpec.describe Pennycress::Input do
  describe "#empty?" do
    it "is true when there are no models" do
      expect(Pennycress::Input.new).to be_empty
    end

    it "is false when models are defined" do
      input = Pennycress::Input.new(model_ids: [:user])

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

  describe "#validate" do
    let(:user_class) { Class.new(ActiveRecord::Base) }
    let(:post_class) { Class.new(ActiveRecord::Base) }

    let(:input) do
      Pennycress::Input.new(
        model_ids: %i[post user]
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
        post: post,
        user: user
      }

      validated = input.validate(value)

      expect(validated[:post]).to have_attributes(model_class: post_class, id: 1)
      expect(validated[:post].record).to equal(post)
      expect(validated[:user]).to have_attributes(model_class: user_class, id: 2)
      expect(validated[:user].record).to equal(user)
    end

    it "accepts primary key values for model inputs" do
      value = {
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
      expect { input.validate(post: post_class.allocate) }.to raise_error(
        Pennycress::ValidationError,
        "missing key: user\npost must be persisted"
      )
    end
  end
end
