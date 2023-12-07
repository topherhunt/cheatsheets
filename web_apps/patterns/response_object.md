# The ResponseObject pattern (Ruby)

ResponseObject instances only respond to the specified fields; if you accidentally try to access an unknown field, it will raise an error. This is much safer and more explicit than the more common pattern of returning an array with positional semantics (eg. an error code + a message) or a hash (which risks giving you unintended nils if you mistype a field name).

```rb
# This pattern is useful when you want to respond from a method with a custom object that
# only responds to specific methods and will raise an error if you mistype any field name.
#
# Usage:
# result = ResponseObject.new(foo: "bar", baz: "yep")
# result.foo # => "bar"
# result.baz # => "yep"
# result.bar # => NoMethodError (undefined method `bar' for #<struct foo="bar", baz="yep">)
#
module ResponseObject
  extend self

  def new(hash)
    raise "must provide a hash" unless hash.is_a?(Hash)
    raise "all keys must be symbols" unless hash.keys.all? { |k| k.is_a?(Symbol) }
    custom_struct = Struct.new(*hash.keys)
    custom_struct.new(*hash.values)
  end
end
```

Elixir gets this for free with the tuple response idiom & pattern matching. We only need it in Ruby.
