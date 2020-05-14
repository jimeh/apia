# frozen_string_literal: true

require 'moonstone/dsls/authenticator'

module Moonstone
  module Definitions
    class Authenticator

      TYPES = [:bearer].freeze

      attr_accessor :id
      attr_accessor :name
      attr_accessor :description
      attr_accessor :type
      attr_accessor :action
      attr_reader :potential_errors

      def initialize(id)
        @id = id
        @potential_errors = []
      end

      def dsl
        @dsl ||= DSLs::Authenticator.new(self)
      end

      def validate(errors)
        if @type.nil?
          errors.add self, 'MissingType', 'A type must be defined for authenticators'
        elsif !TYPES.include?(@type)
          errors.add self, 'InvalidType', "The type must be one of #{TYPES.join(', ')} (was: #{@type.inspect})"
        end

        if @action.nil?
          errors.add self, 'MissingAction', 'An action must be defined for authenticators'
        elsif !@action.is_a?(Proc)
          errors.add self, 'InvalidAction', 'The action provided must be a Proc'
        end

        @potential_errors.each_with_index do |error, index|
          unless error.respond_to?(:ancestors) && error.ancestors.include?(Moonstone::Error)
            errors.add self, 'InvalidPotentialError', "Potential error at index #{index} must be a class that inherits from Moonstone::Error"
          end
        end
      end

    end
  end
end
