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

    # @!attribute [w] seeds
    #   @param value [Proc]
    attr_writer :seeds

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

    # @return [Proc] a block that defines the list of seeds
    # @raise [ValidationError] if seeds are not defined
    def seeds
      raise ValidationError, "seeds are not defined" if @seeds.nil?

      @seeds
    end
  end
end
