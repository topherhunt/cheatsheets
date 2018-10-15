# ActiveRecord & migrations

## Validations

* Keep validations field-focused rather than association-focused. If you `validate :author, presence: true` etc., then you're forcing the association to load every time you try to make changes on this record. That's unperformant.

## Migrations

Add FK references like this:

```
add_integer :conversations, :creator_id, null: false
add_foreign_key :conversations, :users, column: :creator_id
add_index :conversations, :creator_id
```
