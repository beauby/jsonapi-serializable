require 'jsonapi/serializable/resource'

module JSONAPI
  module Serializable
    class Model < Resource
      def self.[](model_klass)
        # TODO(beauby): Memoize the specified base classes. Ensure they are
        #   being subclassed rather than directly modified.
        Class.new(self) do
          type model_klass.to_s
          id
        end
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
              resource_klass.new(model: @model.public_send(rel))
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
              resource_klass.new(model: @model.public_send(rel))
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
