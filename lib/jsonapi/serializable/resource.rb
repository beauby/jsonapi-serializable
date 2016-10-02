require 'jsonapi/serializable/link'
require 'jsonapi/serializable/relationship'
require 'jsonapi/serializable/resource_dsl'

module JSONAPI
  module Serializable
    class Resource
      include ResourceDSL

      class << self
        attr_accessor :type_val, :type_block, :id_block, :attribute_blocks,
                      :relationship_blocks, :link_blocks, :meta_val, :meta_block
      end

      self.attribute_blocks = {}
      self.relationship_blocks = {}
      self.link_blocks = {}

      def self.inherited(klass)
        super
        klass.attribute_blocks = attribute_blocks.dup
        klass.relationship_blocks = relationship_blocks.dup
        klass.link_blocks = link_blocks.dup
      end

      def initialize(param_hash = {})
        param_hash.each { |k, v| instance_variable_set("@#{k}", v) }
        @_id = instance_eval(&self.class.id_block)
        @_type = self.class.type_val || instance_eval(&self.class.type_block)
        @_meta = if self.class.meta_val
                   self.class.meta_val
                 elsif self.class.meta_block
                   instance_eval(&self.class.meta_block)
                 end
        @_attributes = {}
        @_relationships = self.class.relationship_blocks
                              .each_with_object({}) do |(k, v), h|
          h[k] = Relationship.new(param_hash, &v)
        end
        @_links = self.class.link_blocks.each_with_object({}) do |(k, v), h|
          h[k] = Link.as_jsonapi(param_hash, &v)
        end
      end

      def as_jsonapi(params = {})
        hash = {}
        hash[:id] = @_id
        hash[:type] = @_type
        attr = attributes(params[:fields] || self.class.attribute_blocks.keys)
        hash[:attributes] = attr if attr.any?
        rels = relationships(params[:fields] || @_relationships.keys,
                             params[:include] || [])
        hash[:relationships] = rels if rels.any?
        hash[:links] = @_links if @_links.any?
        hash[:meta] = @_meta unless @_meta.nil?

        hash
      end

      def jsonapi_type
        @_type
      end

      def jsonapi_id
        @_id
      end

      def jsonapi_related(include)
        @_relationships
          .select { |k, _| include.include?(k) }
          .each_with_object({}) { |(k, v), h| h[k] = Array(v.data) }
      end

      private

      def attributes(fields)
        self.class.attribute_blocks
            .select { |k, _| !@_attributes.key?(k) && fields.include?(k) }
            .each { |k, v| @_attributes[k] = instance_eval(&v) }
        @_attributes.select { |k, _| fields.include?(k) }
      end

      def relationships(fields, include)
        @_relationships
          .select { |k, _| fields.include?(k) }
          .each_with_object({}) do |(k, v), h|
          h[k] = v.as_jsonapi(include.include?(k))
        end
      end
    end
  end
end
