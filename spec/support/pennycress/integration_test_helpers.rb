# frozen_string_literal: true

DUMMY_ROOT = File.expand_path("../../dummy", __dir__)

module Pennycress
  # Helpers for Pennycress integration tests
  module IntegrationTestHelpers
    # Boots the dummy Rails app for integration tests
    #
    # @return [void]
    def self.boot_rails
      return if defined?(Dummy::Application) && Rails.application.initialized?

      ENV["RAILS_ENV"] = "test"
      ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", DUMMY_ROOT)

      require File.join(DUMMY_ROOT, "config/environment")
    end

    # @return [Array<Hash>]
    def enqueued_jobs
      ActiveJob::Base.queue_adapter.enqueued_jobs
    end

    # @return [void]
    def clear_enqueued_jobs
      enqueued_jobs.clear
    end
  end
end
