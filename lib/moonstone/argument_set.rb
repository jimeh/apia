# frozen_string_literal: true

require 'moonstone/helpers'
require 'moonstone/defineable'
require 'moonstone/definitions/argument_set'
require 'moonstone/errors/missing_argument_error'
require 'moonstone/errors/invalid_argument_error'

module Moonstone
  class ArgumentSet

    extend Defineable

    class << self

      # Return the definition for this argument set
      #
      # @return [Moonstone::Definitions::ArgumentSet]
      def definition
        @definition ||= Definitions::ArgumentSet.new(Helpers.class_name_to_id(name))
      end

      # Finds all objects referenced by this argument set and add them
      # to the provided set.
      #
      # @param set [Moonstone::ObjectSet]
      # @return [void]
      def collate_objects(set)
        definition.arguments.each_value do |argument|
          set.add_object(argument.type)
        end
      end

      # Create a new argument set from a request object
      #
      # @param request [Moonstone::Request]
      # @return [Moonstone::ArgumentSet]
      def create_from_request(request)
        new(request.json_body || request.params || {})
      end

    end

    # Create a new argument set by providing a hash containing the raw
    # arguments
    #
    # @param hash [Hash]
    # @param path [Array]
    # @return [Moonstone::ArgumentSet]
    def initialize(hash, path: [])
      unless hash.is_a?(Hash)
        raise Moonstone::RuntimeError, 'Hash was expected for argument'
      end

      @path = path
      @source = hash.each_with_object({}) do |(key, value), source|
        argument = self.class.definition.arguments[key.to_sym]
        next unless argument

        value = parse_value(argument, value)
        validation_errors = argument.validate_value(value)
        unless validation_errors.empty?
          raise InvalidArgumentError.new(argument, issue: :validation_errors, errors: validation_errors, path: @path + [argument])
        end

        source[key.to_sym] = value
      end
      check_for_missing_required_arguments
    end

    # Return an item from the argument set
    #
    # @param value [String, Symbol]
    # @return [Object, nil]
    def [](value)
      @source[value.to_sym]
    end

    # Return an item from this argument set
    #
    # @param values [Array<String, Symbol>]
    # @return [Object, nil]
    def dig(*values)
      @source.dig(*values)
    end

    private

    def parse_value(argument, value, index: nil)
      if argument.array? && value.is_a?(Array)
        value.each_with_index.map do |v, index|
          parse_value(argument, v, index: index)
        end

      elsif argument.type.ancestors.include?(Moonstone::Scalar)
        begin
          type = argument.type.parse(value)
        rescue Moonstone::ParseError => e
          # If we cannot parse the given input, this is cause for a parse error to be raised.
          raise InvalidArgumentError.new(argument, issue: :parse_error, errors: [e.message], index: index, path: @path + [argument])
        end

        unless argument.type.valid?(type)
          # If value we have parsed is not actually valid, we 'll raise an argument error.
          # In most cases, it is likely that an integer has been provided to string etc...
          raise InvalidArgumentError.new(argument, issue: :invalid_scalar, index: index, path: @path + [argument])
        end

        type

      elsif argument.type.ancestors.include?(Moonstone::ArgumentSet)
        argument.type.new(value, path: @path + [argument])

      elsif argument.type.ancestors.include?(Moonstone::Enum)
        unless argument.type.definition.values[value]
          raise InvalidArgumentError.new(argument, issue: :invalid_enum_value, index: index, path: @path + [argument])
        end

        value
      end
    end

    def check_for_missing_required_arguments
      self.class.definition.arguments.each_value do |arg|
        next unless arg.required?
        next if self[arg.name]

        raise MissingArgumentError.new(arg, path: @path + [arg])
      end
    end

  end
end
