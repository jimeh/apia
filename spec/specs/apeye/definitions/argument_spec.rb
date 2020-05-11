# frozen_string_literal: true

require 'spec_helper'
require 'apeye/definitions/argument'
require 'apeye/manifest_errors'

describe APeye::Definitions::Argument do
  context '#type' do
    it 'should return the type' do
      arg = APeye::Definitions::Argument.new(:name, type: APeye::Scalars::String)
      expect(arg.type).to eq APeye::Scalars::String
    end

    it 'should return a scalar object if a symbol is provided' do
      arg = APeye::Definitions::Argument.new(:name, type: :integer)
      expect(arg.type).to eq APeye::Scalars::Integer
    end
  end

  context '#description' do
    it 'should return the description' do
      arg = APeye::Definitions::Argument.new(:name, type: :string, description: 'Some description')
      expect(arg.description).to eq 'Some description'
    end
  end

  context '#required?' do
    it 'should return true if required' do
      arg = APeye::Definitions::Argument.new(:name, type: :string, required: true)
      expect(arg.required?).to be true
    end

    it 'should return false if not required' do
      arg = APeye::Definitions::Argument.new(:name, type: :string, required: false)
      expect(arg.required?).to be false
    end

    it 'should return false if not specified' do
      arg = APeye::Definitions::Argument.new(:name, type: :string)
      expect(arg.required?).to be false
    end
  end

  context '#array?' do
    it 'should return true if array' do
      arg = APeye::Definitions::Argument.new(:name, type: :string, array: true)
      expect(arg.array?).to be true
    end

    it 'should return false if not array' do
      arg = APeye::Definitions::Argument.new(:name, type: :string, array: false)
      expect(arg.array?).to be false
    end

    it 'should return false if not specified' do
      arg = APeye::Definitions::Argument.new(:name, type: :string)
      expect(arg.array?).to be false
    end
  end

  context '#validate_value' do
    it 'should return an empty array when no validations are defined' do
      arg = APeye::Definitions::Argument.new(:name, type: :string)
      expect(arg.validate_value('hello')).to be_a Array
      expect(arg.validate_value('hello')).to be_empty
    end

    it 'should return the name of any validations that are not true' do
      arg = APeye::Definitions::Argument.new(:name, type: :string)
      arg.validations << { name: 'example1', block: proc { false } }
      arg.validations << { name: 'example2', block: proc { true } }
      expect(arg.validate_value('hello')).to be_a Array
      expect(arg.validate_value('hello').size).to eq 1
      expect(arg.validate_value('hello')).to include('example1')
    end

    it 'should an empty array of all validations are true' do
      arg = APeye::Definitions::Argument.new(:name, type: :string)
      arg.validations << { name: 'example1', block: proc { true } }
      arg.validations << { name: 'example2', block: proc { true } }
      expect(arg.validate_value('hello')).to be_a Array
      expect(arg.validate_value('hello')).to be_empty
    end
  end

  context '#validate' do
    it 'should add no errors for a valid argument' do
      arg = APeye::Definitions::Argument.new(:example, type: :string)
      errors = APeye::ManifestErrors.new
      arg.validate(errors)
      expect(errors.for(arg)).to be_empty
    end

    it 'should add an error if the name is missing' do
      arg = APeye::Definitions::Argument.new(nil, type: :string)
      errors = APeye::ManifestErrors.new
      arg.validate(errors)
      expect(errors.for(arg)).to include 'MissingName'
    end

    it 'should add an error if the name is invalid' do
      arg = APeye::Definitions::Argument.new(:'invalid+name', type: :string)
      errors = APeye::ManifestErrors.new
      arg.validate(errors)
      expect(errors.for(arg)).to include 'InvalidName'
    end

    it 'should add an error if the type is missing' do
      arg = APeye::Definitions::Argument.new(:name)
      errors = APeye::ManifestErrors.new
      arg.validate(errors)
      expect(errors.for(arg)).to include 'MissingType'
    end

    it 'should add an error if the type is a string' do
      arg = APeye::Definitions::Argument.new(:name, type: 'asd')
      errors = APeye::ManifestErrors.new
      arg.validate(errors)
      expect(errors.for(arg)).to include 'MissingType'
    end

    it 'should add an error if the type is not an APeye::Type' do
      arg = APeye::Definitions::Argument.new(:name, type: APeye::Enum.create('MyEnum'))
      errors = APeye::ManifestErrors.new
      arg.validate(errors)
      expect(errors.for(arg)).to include 'InvalidType'
    end
  end
end
