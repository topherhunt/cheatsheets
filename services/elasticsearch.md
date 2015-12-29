# ElasticSearch

## Resources

- https://github.com/elastic/elasticsearch-rails/blob/master/elasticsearch-model/
- http://benjaminknofe.com/blog/2014/06/14/rspec-testing-rails-with-elasticsearch/
- https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html

## Basics

- Run `elasticsearch` in a new tab so the Rails commands have a running service to query against or update

## Installing

- Add to the top of the relevant model:
 `include Elasticsearch::Model
  # Auto update index when objects are created, updated, destroyed
  # (does *not* work in specs if transactional tests are enabled)
  include Elasticsearch::Model::Callbacks
  index_name "pangeo-#{Rails.env}-list-items" # New index for each env`
- Then open the Rails console and run:
  `<ModelName>.__elasticsearch__.import(force: true)`
  This creates the index if absent, and indexes all entries in the db.
- By default, the `elasticsearch-rails` gem calls `as_json` on your model object when indexing, so the JSON stored in the ES database (ie. what's searchable and what's returned) is determined by the `as_json` output.

## Searching

- Basic search: `search = <ModelName>.__elasticsearch__.search("*search term*")`
- Multi-model search: `search = Elasticsearch::Model.search("*bridge*")`
- Pagination: `<ModelName>.__elasticsearch__.search("blah").per(10).page(3)`
- View counts:
  `search.results.count` => 10,
  `search.results.total` => 23
- Get an array of raw ActiveRecord objects:
  `search.records` => [Object, Object...]
- Don't run `ModelName.search("blah")` because #search can be overridden by Ransack and other insensitive gems.
