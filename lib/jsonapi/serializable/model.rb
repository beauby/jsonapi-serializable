require 'jsonapi/serializable/resource'

module JSONAPI
  module Serializable
    class Model < Resource
      def self.type(value = nil)
        value ||= name
        super(value)
      end

      def self.id(&block)
        block ||= proc { @model.public_send(:id).to_s }
        super(&block)
      end

      def self.attribute(attr, &block)
        block ||= proc { @model.public_send(attr) }
        super(attr, &block)
      end

      def self.has_many(rel, resource_klass = nil, &block)
        rel_block = proc do
          if resource_klass
            data do
              @model.public_send(rel).map do |related|
                resource_klass.new(model: related)
              end
            end
          end
          instance_eval(&block) unless block.nil?
        end
        relationship(rel, &rel_block)
      end

      def self.has_one(rel, resource_klass = nil, &block)
        rel_block = proc do
          if resource_klass
            data do
              related = @model.public_send(rel)
              resource_klass.new(model: related)
            end
          end
          instance_eval(&block) unless block.nil?
        end
        relationship(rel, &rel_block)
      end

      def nil?
        @model.nil?
      end

      def as_jsonapi(params = {})
        return nil if nil?
        super(params)
      end
    end
  end
end
