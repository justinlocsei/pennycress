# frozen_string_literal: true

require_relative "pennycress/integration_test_helpers"

RSpec.configure do |config|
  config.include Pennycress::IntegrationTestHelpers, type: :integration

  config.before(:each, type: :integration) do
    Pennycress::IntegrationTestHelpers.boot_rails

    ActiveJob::Base.queue_adapter = :test
    Pennycress::WarmSeedJob.queue_adapter = ActiveJob::Base.queue_adapter
    clear_enqueued_jobs

    Discussion.delete_all
    DiscussionTitle.compute_calls = 0

    Rails.cache.clear
  end
end
