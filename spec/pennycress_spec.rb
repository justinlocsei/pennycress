# frozen_string_literal: true

require "pennycress"
require "pennycress/configuration"

RSpec.describe Pennycress do
  it "exposes a version" do
    expect(Pennycress::VERSION).to be_a(String)
  end

  describe ".configure" do
    it "yields the current configuration" do
      described_class.configure do |config|
        expect(config).to equal(Pennycress::Configuration.current)
      end
    end
  end
end
