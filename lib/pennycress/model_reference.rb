# frozen_string_literal: true

require_relative "errors"

module Pennycress
  # A model reference is a description of a model that can use either a model
  # instance or its primary key.
  class ModelReference
    # @return [Object] the model's scalar or composite primary key
    attr_reader :id

    # @return [ActiveRecord::Base] the referenced ActiveRecord model class
    attr_reader :model_class

    class << self
      # @param value [Object] a model instance or primary key value
      # @param label [String] the input label used in error messages
      # @return [ModelReference]
      # @raise [ValidationError] if the value is invalid
      def normalize(model_class, value, label:)
        result =
          if value.is_a?(model_class)
            normalize_instance(model_class, value)
          elsif model_class.composite_primary_key?
            normalize_composite_key(model_class, value)
          else
            normalize_scalar_key(model_class, value)
          end

        raise ValidationError, "#{label} #{result}" if result.is_a?(String)

        result
      end

    private

      # @param model_class [ActiveRecord::Base]
      # @param value [Object]
      # @return [ModelReference, String]
      def normalize_composite_key(model_class, value)
        length = model_class.primary_key.length

        unless value.is_a?(Array)
          return "must be a #{model_class.name} or an array of #{length} key values"
        end

        if value.length != length
          "must have #{length} primary key values, got #{value.length}"
        elsif value.any? { |item| !scalar_key?(item) }
          "primary keys must use scalar values"
        else
          new(id: value, model_class: model_class)
        end
      end

      # @param model_class [ActiveRecord::Base]
      # @param instance [ActiveRecord::Base]
      # @return [ModelReference, String]
      def normalize_instance(model_class, instance)
        id =
          begin
            instance.id
          rescue NoMethodError
            nil
          end

        if id.nil? || (instance.respond_to?(:new_record?) && instance.new_record?)
          return "must be persisted"
        end

        new(id: id, model_class: model_class, record: instance)
      end

      # @param model_class [ActiveRecord::Base]
      # @param value [Object]
      # @return [ModelReference, String]
      def normalize_scalar_key(model_class, value)
        if scalar_key?(value)
          new(id: value, model_class: model_class)
        else
          "must be a #{model_class.name} or a primary key value: #{value.inspect}"
        end
      end

      # @param value [Object]
      # @return [Boolean]
      def scalar_key?(value)
        !value.nil? && !value.is_a?(Array) && !value.is_a?(Hash)
      end
    end

    # Creates a model reference
    #
    # @param id [Object] the model's scalar or composite primary key
    # @param model_class [Class] the referenced ActiveRecord model class
    # @param record [ActiveRecord::Base, nil] a loaded record, when one is available
    def initialize(id:, model_class:, record: nil)
      @id = id
      @model_class = model_class
      @record = record
    end

    # @return [Array<String>] cache key segments for this reference's ID
    def cache_key
      Array(id).map(&:to_s)
    end

    # @return [ActiveRecord::Base] the referenced model instance
    def record
      @record ||= model_class.find(id)
    end
  end
end
