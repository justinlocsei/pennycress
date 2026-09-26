# frozen_string_literal: true

require "active_job"

require_relative "configuration"

module Pennycress
  # Warms cached outputs for one value seed.
  class WarmSeedJob < ActiveJob::Base
    queue_as { Configuration.current.warming_queue }

    # @param value_class_name [String] the value class to warm
    # @param seed [Object] the seed to warm
    # @return [void]
    def perform(value_class_name, seed)
      value_class_name.constantize.new.warm_seed(seed)
    end
  end
end
