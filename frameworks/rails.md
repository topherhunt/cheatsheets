# Rails

## Cache

- I love the low-level cache. Works with any kind of object.
- `Rails.cache.fetch(key, expires_in: 1.month) { ...heavy expression... }`

## Runners

- `rails runner lib/runner_file.rb ARG1 ARG2`
