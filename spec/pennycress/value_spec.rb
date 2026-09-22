# frozen_string_literal: true

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
end
