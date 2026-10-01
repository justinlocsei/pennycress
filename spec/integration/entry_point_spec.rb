# frozen_string_literal: true

require "open3"
require "pennycress/version"

RSpec.describe "the Pennycress entry point" do
  it "loads without a Rails application" do
    stdout, stderr, status = Open3.capture3(
      "bundle",
      "exec",
      "ruby",
      "-e",
      "require 'pennycress'; print Pennycress::VERSION"
    )

    expect(status).to be_success, stderr
    expect(stdout).to eq(Pennycress::VERSION)
  end
end
