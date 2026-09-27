# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  cover "lib/**/*.rb"
  skip "lib/pennycress/version.rb"
  skip "spec/"
end
