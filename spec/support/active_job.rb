# frozen_string_literal: true

require "logger"

RSpec.configure do |config|
  config.before do
    next unless defined?(ActiveJob::Base)

    ActiveJob::Base.logger = Logger.new(File::NULL)
  end
end
