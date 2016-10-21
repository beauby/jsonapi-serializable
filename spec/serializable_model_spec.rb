require 'jsonapi/serializable'

class Model
  def initialize(params)
    params.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
  end
end

class User < Model
  attr_accessor :id, :name, :address, :posts
end

class Post < Model
  attr_accessor :id, :title, :date, :author
end

describe JSONAPI::Serializable::Model, '#as_jsonapi' do
  before(:all) do
    @users = [
      User.new(id: 1, name: 'User 1', address: '123 Example st.', posts: []),
      User.new(id: 2, name: 'User 2', address: '123 Example st.', posts: [])
    ]
    @posts = [
      Post.new(id: 1, title: 'Post 1', date: 'yesterday', author: @users[1]),
      Post.new(id: 2, title: 'Post 2', date: 'today', author: @users[0]),
      Post.new(id: 3, title: 'Post 3', date: 'tomorrow', author: @users[1]),
      Post.new(id: 4, title: 'Post 4', date: 'tomorrow')
    ]
    @users[1].posts = [@posts[0], @posts[2]]
    @users[0].posts = [@posts[1]]
  end

  it 'infers type and id' do
    user_klass = Class.new(JSONAPI::Serializable::Model[User])
    resource = user_klass.new(model: @users[0])
    actual = resource.as_jsonapi
    expected = {
      type: 'User',
      id: '1'
    }

    expect(actual).to eq(expected)
  end

  it 'handles attributes' do
    user_klass = Class.new(JSONAPI::Serializable::Model[User]) do
      attribute :name
      attribute :address
    end
    resource = user_klass.new(model: @users[0])
    actual = resource.as_jsonapi
    expected = {
      type: 'User',
      id: '1',
      attributes: {
        name: 'User 1',
        address: '123 Example st.'
      }
    }

    expect(actual).to eq(expected)
  end

  it 'handles included has_one relationships' do
    user_klass = Class.new(JSONAPI::Serializable::Model[User])
    post_klass = Class.new(JSONAPI::Serializable::Model[Post]) do
      has_one :author, user_klass
    end
    resource = post_klass.new(model: @posts[0])
    actual = resource.as_jsonapi(include: [:author])
    expected = {
      type: 'Post',
      id: '1',
      relationships: {
        author: {
          data: { type: 'User', id: '2' }
        }
      }
    }

    expect(actual).to eq(expected)
  end

  it 'handles non-included has_one relationships' do
    user_klass = Class.new(JSONAPI::Serializable::Model[User])
    post_klass = Class.new(JSONAPI::Serializable::Model[Post]) do
      has_one :author, user_klass do
        link(:self) do
          "http://api.example.com/posts/#{@model.id}/relationships/author"
        end
      end
    end
    resource = post_klass.new(model: @posts[0])
    actual = resource.as_jsonapi
    expected = {
      type: 'Post',
      id: '1',
      relationships: {
        author: {
          links: {
            self: 'http://api.example.com/posts/1/relationships/author'
          }
        }
      }
    }

    expect(actual).to eq(expected)
  end

  it 'handles nil has_one relationships' do
    user_klass = Class.new(JSONAPI::Serializable::Model[User])
    post_klass = Class.new(JSONAPI::Serializable::Model[Post]) do
      has_one :author, user_klass
    end
    resource = post_klass.new(model: @posts[3])
    actual = resource.as_jsonapi
    expected = {
      type: 'Post',
      id: '4',
      relationships: {
        author: {
          data: nil
        }
      }
    }

    expect(actual).to eq(expected)
  end

  it 'falls back to linkage data for non-included has_one relationships' do
    user_klass = Class.new(JSONAPI::Serializable::Model[User])
    post_klass = Class.new(JSONAPI::Serializable::Model[Post]) do
      has_one :author, user_klass
    end
    resource = post_klass.new(model: @posts[0])
    actual = resource.as_jsonapi
    expected = {
      type: 'Post',
      id: '1',
      relationships: {
        author: {
          data: { type: 'User', id: '2' }
        }
      }
    }

    expect(actual).to eq(expected)
  end

  # it 'does not include data when relationship is not included' do
  #   user_klass = Class.new(JSONAPI::Serializable::Resource) do
  #     type 'users'
  #     id { @user.id.to_s }
  #     relationship(:posts) do
  #       link(:self) { "http://api.example.com/users/#{@user.id}/relationships/posts" }
  #       link(:related) { "http://api.example.com/users/#{@user.id}/posts" }
  #       meta(rel_meta: 'some meta')
  #       data do
  #         @user.posts.map do |p|
  #           post_klass.new(post: p, UrlHelper: @url_helper)
  #         end
  #       end
  #     end
  #   end
  #   resource = user_klass.new(user: @users[0], url_helper: UrlHelper)
  #   actual = resource.as_jsonapi
  #   expected = {
  #     type: 'users',
  #     id: '1',
  #     relationships: {
  #       posts: {
  #         links: {
  #           self: 'http://api.example.com/users/1/relationships/posts',
  #           related: 'http://api.example.com/users/1/posts'
  #         },
  #         meta: {
  #           rel_meta: 'some meta'
  #         }
  #       }
  #     }
  #   }

  #   expect(actual).to eq(expected)
  # end

  # it 'includes data when relationship is included' do
  #   post_klass = Class.new(JSONAPI::Serializable::Resource) do
  #     type 'posts'
  #     id { @post.id.to_s }
  #   end
  #   user_klass = Class.new(JSONAPI::Serializable::Resource) do
  #     type 'users'
  #     id { @user.id.to_s }
  #     relationship(:posts) do
  #       link(:self) { "http://api.example.com/users/#{@user.id}/relationships/posts" }
  #       link(:related) { "http://api.example.com/users/#{@user.id}/posts" }
  #       meta(rel_meta: 'some meta')
  #       data do
  #         @user.posts.map do |p|
  #           post_klass.new(post: p, UrlHelper: @url_helper)
  #         end
  #       end
  #     end
  #   end
  #   resource = user_klass.new(user: @users[0], url_helper: UrlHelper)
  #   actual = resource.as_jsonapi(include: [:posts])
  #   expected = {
  #     type: 'users',
  #     id: '1',
  #     relationships: {
  #       posts: {
  #         links: {
  #           self: 'http://api.example.com/users/1/relationships/posts',
  #           related: 'http://api.example.com/users/1/posts'
  #         },
  #         meta: {
  #           rel_meta: 'some meta'
  #         },
  #         data: [
  #           { id: '2', type: 'posts' }
  #         ]
  #       }
  #     }
  #   }

  #   expect(actual).to eq(expected)
  # end

  # it 'filters out relationships' do
  #   user_klass = Class.new(JSONAPI::Serializable::Resource) do
  #     type 'users'
  #     id { @user.id.to_s }
  #     attribute(:name) { @user.name }
  #     attribute(:address) { @user.address }
  #     relationship(:posts) do
  #       link(:self) { "http://api.example.com/users/#{@user.id}/relationships/posts" }
  #       link(:related) { "http://api.example.com/users/#{@user.id}/posts" }
  #       meta(rel_meta: 'some meta')
  #     end
  #   end
  #   resource = user_klass.new(user: @users[0], url_helper: UrlHelper)
  #   actual = resource.as_jsonapi(fields: [:name, :address])
  #   expected = {
  #     type: 'users',
  #     id: '1',
  #     attributes: {
  #       name: 'User 1',
  #       address: '123 Example st.'
  #     }
  #   }

  #   expect(actual).to eq(expected)
  # end

  # it 'filters out attributes' do
  #   user_klass = Class.new(JSONAPI::Serializable::Resource) do
  #     type 'users'
  #     id { @user.id.to_s }
  #     attribute(:name) { @user.name }
  #     attribute(:address) { @user.address }
  #     relationship(:posts) do
  #       link(:self) { "http://api.example.com/users/#{@user.id}/relationships/posts" }
  #       link(:related) { "http://api.example.com/users/#{@user.id}/posts" }
  #       meta(rel_meta: 'some meta')
  #     end
  #   end
  #   resource = user_klass.new(user: @users[0], url_helper: UrlHelper)
  #   actual = resource.as_jsonapi(fields: [:name, :posts])
  #   expected = {
  #     type: 'users',
  #     id: '1',
  #     attributes: {
  #       name: 'User 1'
  #     },
  #     relationships: {
  #       posts: {
  #         links: {
  #           self: 'http://api.example.com/users/1/relationships/posts',
  #           related: 'http://api.example.com/users/1/posts'
  #         },
  #         meta: {
  #           rel_meta: 'some meta'
  #         }
  #       }
  #     }
  #   }

  #   expect(actual).to eq(expected)
  # end
end
