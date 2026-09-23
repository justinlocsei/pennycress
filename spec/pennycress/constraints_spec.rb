# frozen_string_literal: true

require "pennycress/constraints"

RSpec.describe Pennycress::Constraints do
  it "raises NotImplementedError with the class and method name" do
    test_class = Class.new do
      include Pennycress::Constraints

      def alfa = require_method(:alfa)
      def bravo = require_method(:bravo)
    end

    stub_const("TestClass", test_class)
    test = TestClass.new

    expect { test.alfa }.to raise_error(
      NotImplementedError,
      "TestClass must implement #alfa"
    )

    expect { test.bravo }.to raise_error(
      NotImplementedError,
      "TestClass must implement #bravo"
    )
  end
end
