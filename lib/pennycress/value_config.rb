# frozen_string_literal: true

require_relative "errors"
require_relative "input"
require_relative "output"
require_relative "watched_model"

module Pennycress
  # A value config holds data describing how a value behaves.
  class ValueConfig
    # @!attribute [w] input
    #   @param value [Input]
    attr_writer :input

    # @!attribute [w] output
    #   @param value [Output]
    attr_writer :output

    # @!attribute [w] seeds
    #   @param value [Proc]
    attr_writer :seeds

    # @return [Input] the schema for the value's input
    # @raise [ValidationError] if a schema is incomplete
    def input
      raise ValidationError, "input is not defined" if @input.nil?
      raise ValidationError, "input is empty" if @input.empty?

      @input
    end

    # @return [Output] the schema for the value's output
    # @raise [ValidationError] if a schema is not defined
    def output
      raise ValidationError, "output is not defined" if @output.nil?

      @output
    end

    # @return [Proc] a block that defines the list of seeds
    def seeds
      @seeds ||= proc { [] }
    end

    # @return [Array<WatchedModel>] watches registered for the value
    def watches
      @watches ||= []
    end
  end
end
