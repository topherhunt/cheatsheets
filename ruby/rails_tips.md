# Rails

http://www.codefellows.org/blog/this-is-why-learning-rails-is-hard/


## Cache

- I love the low-level cache. Works with any kind of object.
- `Rails.cache.fetch(key, expires_in: 1.month) { ...heavy expression... }`


## ActiveRecord: validations

* Keep validations field-focused rather than association-focused. If you `validate :author, presence: true` etc., then you're forcing the association to load every time you try to make changes on this record. That's unperformant.


## ActiveRecord: migrations

Adding FK references:

```
add_integer :conversations, :creator_id, null: false
add_foreign_key :conversations, :users, column: :creator_id
add_index :conversations, :creator_id
```


## Tests: Capybara

  * `save_and_open_screenshot()`
