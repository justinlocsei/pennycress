# frozen_string_literal: true

require "active_record"
require "active_support/core_ext/string/inflections"

require_relative "errors"

module Pennycress
  # This module contains helpers for working with references to ActiveRecord
  # models that follow Rails naming conventions like `:uploaded_file`.
  module Models
    class << self
      # Resolve a model ID to a class
      #
      # @param id [Symbol] a model ID (e.g., `:uploaded_file`)
      # @return [ActiveRecord::Base] the model class
      # @raise [ValidationError] if the model ID cannot be resolved
      # @raise [ValidationError] if the resolved class is not a model
      def resolve(id)
        begin
          model = id.to_s.classify.constantize
        rescue NameError => e
          raise ValidationError, "unknown model #{id.inspect}", cause: e
        end

        unless model < ActiveRecord::Base
          raise ValidationError, "#{model.name} is not an ActiveRecord model"
        end

        model
      end
    end
  end
end
