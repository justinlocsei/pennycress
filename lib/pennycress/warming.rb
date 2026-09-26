# frozen_string_literal: true

require_relative "registry"
require_relative "warm_seed_job"

module Pennycress
  # Orchestrates cache warming for registered values.
  module Warming
    class << self
      # Warms cached outputs for each registered value seed
      #
      # @param async [Boolean] whether to warm the cache via jobs or synchronous operations
      # @return [void]
      # @raise [ArgumentError] if a value class has no name
      def warm_cache(async: true)
        method = async ? :perform_later : :perform_now

        Registry.current.values.each do |value_class|
          value_class.seeds.each do |seed|
            name = value_class.name

            unless name
              raise ArgumentError, "value class must have a name"
            end

            WarmSeedJob.send(method, name, seed)
          end
        end
      end
    end
  end
end
