# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  cover "lib/**/*.rb"
  minimum_coverage 100
  skip "lib/pennycress/version.rb"
  skip "spec/"
end
