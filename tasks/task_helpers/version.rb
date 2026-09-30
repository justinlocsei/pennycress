# frozen_string_literal: true

module Pennycress
  # This module provides methods for handling user-provided version strings.
  module TaskHelpers
    # Validate a release version
    #
    # @param version [String] a user-provided version
    # @return [String] a valid version identifier
    def self.require_version(version)
      if version.nil? || version.empty?
        abort "A version must be provided in brackets"
      end

      unless version.match?(/\A\d+\.\d+\.\d+\z/)
        abort "A version must use major.minor.patch format"
      end

      version
    end
  end
end
