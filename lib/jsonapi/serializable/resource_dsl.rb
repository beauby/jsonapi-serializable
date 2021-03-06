module JSONAPI
  module Serializable
    module ResourceDSL
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # @overload type(value)
        #   Declare the JSON API type of this resource.
        #   @param [String] value The value of the type.
        #
        #   @example
        #     type 'users'
        #
        # @overload type(value)
        #   Declare the JSON API type of this resource.
        #   @yieldreturn [String] The value of the type.
        #
        #   @example
        #     type { @user.admin? ? "admin" : "users" }
        def type(value = nil, &block)
          self.type_val = value
          self.type_block = block
        end

        # Declare the JSON API id of this resource.
        #
        # @yieldreturn [String] The id of the resource.
        #
        # @example
        #   id { @user.id.to_s }
        def id(&block)
          self.id_block = block
        end

        # @overload meta(value)
        #   Declare the meta information for this resource.
        #   @param [Hash] value The meta information hash.
        #
        #   @example
        #     meta key: value
        #
        # @overload meta(&block)
        #   Declare the meta information for this resource.
        #   @yieldreturn [String] The meta information hash.
        #   @example
        #     meta do
        #       { key: value }
        #     end
        def meta(value = nil, &block)
          self.meta_val = value
          self.meta_block = block
        end

        # Declare an attribute for this resource.
        #
        # @param [Symbol] name The key of the attribute.
        # @yieldreturn [Hash, String, nil] The block to compute the value.
        #
        # @example
        #   attribute(:name) { @user.name }
        def attribute(name, &block)
          attribute_blocks[name] = block
        end

        # Declare a relationship for this resource. The properties of the
        #   relationship are set by providing a block in which the DSL methods
        #   of +JSONAPI::Serializable::Relationship+ are called.
        # @see JSONAPI::Serializable::Relationship
        #
        # @param [Symbol] name The key of the relationship.
        #
        # @example
        #   relationship :posts do
        #     data { @user.posts.map { |p| PostResource.new(post: p) } }
        #   end
        #
        # @example
        #   relationship :author do
        #     data do
        #       @post.author && UserResource.new(user: @post.author)
        #     end
        #     linkage_data do
        #       { type: 'users', id: @post.author_id }
        #     end
        #     link(:self) do
        #       "http://api.example.com/posts/#{@post.id}/relationships/author"
        #     end
        #     link(:related) do
        #       "http://api.example.com/posts/#{@post.id}/author"
        #     end
        #     meta do
        #       { author_online: @post.author.online? }
        #     end
        #   end
        def relationship(name, &block)
          relationship_blocks[name] = block
        end

        # Declare a link for this resource. The properties of the link are set
        #   by providing a block in which the DSL methods of
        #   +JSONAPI::Serializable::Link+ are called, or the value of the link
        #   is returned directly.
        # @see JSONAPI::Serialiable::Link
        #
        # @param [Symbol] name The key of the link.
        # @yieldreturn [Hash, String, nil] The block to compute the value, if
        #   any.
        #
        # @example
        #   link(:self) do
        #     "http://api.example.com/users/#{@user.id}"
        #   end
        #
        # @example
        #    link(:self) do
        #      href "http://api.example.com/users/#{@user.id}"
        #      meta is_self: true
        #    end
        def link(name, &block)
          link_blocks[name] = block
        end
      end
    end
  end
end
