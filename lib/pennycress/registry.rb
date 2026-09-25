# frozen_string_literal: true

module Pennycress
  # Tracks value classes registered at load time.
  class Registry
    class << self
      # @return [Registry] the current registry
      def current
        @current ||= new
      end

      # Runs a block with a temporary registry
      #
      # @param registry [Registry] the registry to use
      # @yield run a block in which the given registry is the current one
      # @return [Object] the block's return value
      def override(registry)
        previous = @current
        @current = registry

        yield
      ensure
        @current = previous
      end
    end

    # Creates a registry
    def initialize
      @values = []
    end

    # @param value [Value] a value class
    # @return [void]
    def register(value)
      @values << value
    end

    # Clears registered value classes
    #
    # @return [void]
    def reset
      @values = []
    end

    # @return [Array<Value>] registered value classes
    def values
      @values
    end
  end
end
