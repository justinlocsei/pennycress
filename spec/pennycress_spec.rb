# frozen_string_literal: true

require "pennycress"

RSpec.describe Pennycress do
  it "exposes a version" do
    expect(Pennycress::VERSION).to be_a(String)
  end
end
