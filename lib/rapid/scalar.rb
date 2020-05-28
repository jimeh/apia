# frozen_string_literal: true

require 'rapid/helpers'
require 'rapid/definitions/scalar'
require 'rapid/defineable'

module Rapid
  class Scalar

    extend Defineable

    # Return the definition for this type
    #
    # @return [Rapid::Definitions::Object]
    def self.definition
      @definition ||= Definitions::Scalar.new(Helpers.class_name_to_id(name))
    end

    def self.cast(value = nil, &block)
      if block_given? && value.nil?
        return definition.dsl.cast(&block)
      end

      unless valid?(value)
        # Before casting, we'll also validate...
        raise InvalidScalarValueError.new(self, value)
      end

      value = definition.cast.call(value) if definition.cast

      value
    end

    def self.valid?(value)
      return true if definition.validator.nil?

      definition.validator.call(value)
    end

    def self.parse(value = nil, &block)
      if block_given? && value.nil?
        return definition.dsl.parse(&block)
      end

      return value if definition.parse.nil?
      return nil if value.nil?

      definition.parse.call(value)
    end

  end
end
