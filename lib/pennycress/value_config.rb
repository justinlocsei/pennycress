# frozen_string_literal: true

require_relative "input_set"

module Pennycress
  # A value config holds data describing how a value behaves.  This includes
  # inputs, invalidation conditions, and partitions.
  class ValueConfig
    # @return [InputSet] the inputs for the value
    attr_reader :inputs

    # Creates a value config
    def initialize
      @inputs = InputSet.new
    end
  end
end
