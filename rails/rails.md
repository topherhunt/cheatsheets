# Rails

http://www.codefellows.org/blog/this-is-why-learning-rails-is-hard/

## Cache

- I love the low-level cache. Works with any kind of object.
- `Rails.cache.fetch(key, expires_in: 1.month) { ...heavy expression... }`
