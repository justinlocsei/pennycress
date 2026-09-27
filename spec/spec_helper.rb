# frozen_string_literal: true

require "support/simplecov"

require "pennycress/registry"
require "support/active_job"
require "support/integration"
require "support/pennycress/test_helpers"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include Pennycress::TestHelpers

  config.define_derived_metadata(file_path: %r{/spec/integration/}) do |metadata|
    metadata[:type] = :integration
  end

  config.define_derived_metadata(file_path: %r{/spec/pennycress/}) do |metadata|
    metadata[:type] = :unit
  end

  config.around(:each, type: :unit) do |example|
    registry = Pennycress::Registry.new
    configuration = Pennycress::Configuration.new

    Pennycress::Registry.override(registry) do
      Pennycress::Configuration.override(configuration) do
        example.run
      end
    end
  end
end
