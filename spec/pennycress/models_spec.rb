# frozen_string_literal: true

require "active_record"
require "pennycress/errors"
require "pennycress/models"

RSpec.describe Pennycress::Models do
  describe ".resolve" do
    it "resolves a model ID to a class" do
      uploaded_file = Class.new(ActiveRecord::Base)
      user = Class.new(ActiveRecord::Base)

      stub_const("UploadedFile", uploaded_file)
      stub_const("User", user)

      expect(described_class.resolve(:uploaded_file)).to eq(uploaded_file)
      expect(described_class.resolve(:user)).to eq(user)
    end

    it "raises an error if the model ID is not found" do
      expect {
        described_class.resolve(:is_not_a_model)
      }.to raise_error(Pennycress::ValidationError, /unknown/)
    end

    it "raises an error if a resolved class is not a model" do
      stub_const("NotAModel", Class.new)

      expect {
        described_class.resolve(:not_a_model)
      }.to raise_error(Pennycress::ValidationError, /NotAModel/)
    end
  end
end
