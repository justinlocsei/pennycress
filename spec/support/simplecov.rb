# frozen_string_literal: true

return if ENV["NO_COVERAGE"]

require "simplecov"

SimpleCov.command_name "RSpec"

SimpleCov.start do
  skip "/spec/"
  group "Library", "lib"
  cover "lib/**/*.rb"
end
