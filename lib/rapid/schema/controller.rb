# frozen_string_literal: true

require 'rapid/controller'
require 'rapid/authenticator'
require 'rapid/schema/object_schema_polymorph'
require 'rapid/schema/route_set_schema_type'

module Rapid
  module Schema
    class Controller < Rapid::Controller

      no_schema

      authenticator do
        type :anonymous
      end

      name 'API Schema'
      description 'Provides endpoint to interrogate the API schema'
      endpoint :schema do
        no_schema
        description 'Returns a payload outlining the full schema of the API'
        field :schema_version, type: :integer
        field :host, type: :string
        field :namespace, type: :string
        field :api, type: :string
        field :objects, type: [ObjectSchemaPolymorph]
        action do |request, response|
          puts request.field_spec.inspect
          response.add_field :schema_version, 1
          response.add_field :objects, request.api.objects.map(&:definition).select(&:schema?)
          response.add_field :api, request.api.definition.id
          response.add_field :namespace, request.namespace
          response.add_field :host, request.host
        end
      end

    end
  end
end
