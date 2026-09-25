# frozen_string_literal: true

require "support/pennycress/test_helpers"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include Pennycress::TestHelpers
end
