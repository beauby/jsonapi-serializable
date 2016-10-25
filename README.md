# jsonapi-serializable
Ruby gem for building [JSON API](http://jsonapi.org) resources to be rendered by
the [jsonapi-renderer](https://github.com/beauby/jsonapi) gem.

## Status

[![Gem Version](https://badge.fury.io/rb/jsonapi-serializable.svg)](https://badge.fury.io/rb/jsonapi-serializable)
[![Build Status](https://secure.travis-ci.org/beauby/jsonapi-serializable.svg?branch=master)](http://travis-ci.org/beauby/jsonapi-serializable?branch=master)

## Installation
```ruby
# In Gemfile
gem 'jsonapi-serializable'
```
then
```
$ bundle
```
or manually via
```
$ gem install jsonapi-serializable
```

## Usage

First, require the gem:
```ruby
require 'jsonapi/serializable'
```

Then, define some resource classes:

### For model-based resources

For resources that are simple representations of models, the DSL is simplified:

```ruby
class PostResource < JSONAPI::Serializable::Resource
  type 'posts'

  id

  attribute :title

  attribute :date do
    @model.created_at
  end

  relationship :author, UserResource do
    link(:self) do
      href @url_helper.link_for_rel('posts', @model.id, 'author')
      meta link_meta: 'some meta'
    end
    link(:related) { @url_helper.link_for_res('users', @model.author.id) }
    meta do
      { relationship_meta: 'some meta' }
    end
  end

  has_many :comments

  meta do
    { resource_meta: 'some meta' }
  end

  link(:self) do
    @url_helper.link_for_res('posts', @model.id)
  end
end
```
Then, build your resources from your models and render them:
```ruby
# post = some post model
# UrlHelper is some helper class
resource = PostResource.new(model: post, url_helper: UrlHelper)
document = JSONAPI.render(resource)
```

### For general resources

In case your resource is not a simple representation of one of your models,
the more general `JSONAPI::Serializable::Resource` class can be used.

```ruby
class PostResource < JSONAPI::Serializable::Resource
  type 'posts'

  id do
    @post.id.to_s
  end

  attribute :title do
    @post.title
  end

  attribute :date do
    @post.date
  end

  relationship :author do
    link(:self) do
      href @url_helper.link_for_rel('posts', @post.id, 'author')
      meta link_meta: 'some meta'
    end
    link(:related) { @url_helper.link_for_res('users', @post.author.id) }
    data do
      if @post.author.nil?
        nil
      else
        UserResource.new(user: @post.author, url_helper: @url_helper)
      end
    end
    meta do
      { relationship_meta: 'some meta' }
    end
  end

  meta do
    { resource_meta: 'some meta' }
  end

  link(:self) do
    @url_helper.link_for_res('posts', @post.id)
  end
end
```
Finally, build your resources from your models and render them:
```ruby
# post = some post model
# UrlHelper is some helper class
resource = PostResource.new(post: post, url_helper: UrlHelper)
document = JSONAPI.render(resource)
```

## License

jsonapi-serializable is released under the [MIT License](http://www.opensource.org/licenses/MIT).
