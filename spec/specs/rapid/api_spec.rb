# frozen_string_literal: true

require 'spec_helper'
require 'rapid/api'
require 'rapid/authenticator'
require 'rapid/controller'

describe Rapid::API do
  context '.objects' do
    it 'should return itself' do
      api = Rapid::API.create('ExampleAPI')
      expect(api.objects).to include api
    end

    it 'should return authenticators' do
      auth = Rapid::Authenticator.create('MainAuth')
      api = Rapid::API.create('BaseAPI') { authenticator auth }
      expect(api.objects).to include auth
    end

    it 'should return controllers referenced by routes' do
      controller = Rapid::Controller.create('Controller')
      api = Rapid::API.create('BaseAPI') do
        routes do
          get 'virtual_machines', controller: controller
        end
      end
      expect(api.objects).to include controller
    end
  end

  context '.validate_all' do
    it 'should return a manifest errors object' do
      api = Rapid::API.create('ExampleAPI')
      expect(api.validate_all).to be_a Rapid::ManifestErrors
      expect(api.validate_all.empty?).to be true
    end

    it 'should find errors on any objects that may exist' do
      controller = Rapid::Controller.create('Controller') do
        endpoint :test do
          # missing action
        end
      end
      api = Rapid::API.create('ExampleAPI') do
        authenticator do
          type :bearer
          # missing action
        end
        routes { get('test', controller: controller, endpoint: :test) }
      end
      errors = api.validate_all
      expect(errors).to be_a Rapid::ManifestErrors

      authenticator_errors = errors.for(api.definition.authenticator.definition)
      expect(authenticator_errors).to_not be_empty
      expect(authenticator_errors).to include 'MissingAction'

      endpoint = api.definition.route_set.find(:get, 'test').first.endpoint
      endpoint_errors = errors.for(endpoint.definition)
      expect(endpoint_errors).to_not be_empty
      expect(endpoint_errors).to include 'MissingAction'
    end
  end

  context '.schema' do
    it 'should return the schema' do
      api = Rapid::API.create('ExampleAPI')
      schema = api.schema(host: 'api.example.com', namespace: 'v1')
      expect(schema['host']).to eq 'api.example.com'
      expect(schema['namespace']).to eq 'v1'
      expect(schema['objects']).to be_a Array
      expect(schema['api']).to eq 'ExampleAPI'
    end
  end
end
