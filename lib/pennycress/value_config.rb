# frozen_string_literal: true

require_relative "errors"
require_relative "input_set"
require_relative "output"

module Pennycress
  # A value config holds data describing how a value behaves.
  class ValueConfig
    # @!attribute [w] inputs
    #   @param value [InputSet]
    attr_writer :inputs

    # @!attribute [w] output
    #   @param value [Output]
    attr_writer :output

    # @return [InputSet] the inputs for the value
    # @raise [ValidationError] if inputs are not present
    def inputs
      raise ValidationError, "inputs are not defined" if @inputs.nil?
      raise ValidationError, "inputs are empty" if @inputs.empty?

      @inputs
    end

    # @return [Output] the output for the value
    # @raise [ValidationError] if output is not defined
    def output
      raise ValidationError, "output is not defined" if @output.nil?

      @output
    end
  end
end
