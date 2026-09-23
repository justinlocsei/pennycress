# frozen_string_literal: true

module Pennycress
  # This module provides a collection of helpers for enforcing constraints on
  # user-facing classes.
  module Constraints
    # Raises an error stating that the named method is required
    #
    # @param name [Symbol] the name of the method
    # @raise [NotImplementedError]
    def require_method(name)
      raise NotImplementedError, "#{self.class} must implement ##{name}"
    end
  end
end
