# frozen_string_literal: true

require "pennycress/registry"
require "support/active_job"
require "support/pennycress/test_helpers"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include Pennycress::TestHelpers

  config.around do |example|
    Pennycress::Registry.override(Pennycress::Registry.new) { example.run }
  end
end
