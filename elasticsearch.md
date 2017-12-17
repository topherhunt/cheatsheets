## Dev & prod

In production, ideally use a managed service like Heroku Bonsai.

In development, `brew install elasticsearch` then I can run `elasticsearch` to start the local server.

## Installing

For basic Rails integration, include the gem [elasticsearch-model](https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model).

Under the good, this gem uses the ES driver [elasticsearch](https://github.com/elastic/elasticsearch-ruby).

## Setting up search integration

In your model, include the helper methods and callbacks:

```
include Elasticsearch::Model
include Elasticsearch::Model::Callbacks # will auto-update index on changes
index_name "pangeo-#{Rails.env}-lists" # Separate ES index for each environment
```

Or if you need more control over what's indexed, write the callbacks yourself:

```
after_commit on: [:create]  { __elasticsearch__.index_document if published? }
after_commit on: [:update]  { __elasticsearch__.update_document if published? }
after_commit on: [:destroy] { __elasticsearch__.delete_document if published? }
```

Specify how each record should be indexed:

```
# defaults to just `self.as_json()`
def as_indexed_json(options={}) # ElasticSearch integration
  self.as_json(
    only: [:title, :published_content],
    include: {
      author: {only: :full_name},
      tags: {only: :name},
      descendants: {only: :published_content}
    }
  )
end
```

Import all pre-existing data if needed:

```
Article.import
```

Basic searching:

```
response = Article.__elasticsearch__.search("basic string")
response.results # returns an array of Hashie JSON results
response.results.total
response.results.first._source
response.records.to_a # load the associated ActiveRecord objects by id
```

Advanced searching example:

```
# see the ElasticSearch query DSL for how to use highlight etc. properly
Article.search(
  query: {match: {title: "Fox dogs"}},
  highlight: {fields: {title: {}}}
)
```

Other search options:

- Use `from` and `size` to paginate

## Diagnostics

```
Article.__elasticsearch__.client.cluster.health
Project.__elasticsearch__.client.indices.get_mapping
Article.__elasticsearch__.search("abc").results.first._index # => "pangeo-development-lists"
```

## Testing

Call a `reindex_elasticsearch!` helper in each relevant test:

```
def reindex_elasticsearch!
  unless `ps aux | grep elasticsearch | grep -v grep | wc -l`.to_i >= 1
    raise "`elasticsearch` doesn't seem to be running. Start it before running this test."
  end

  # ES-related callbacks don't work in transactional tests, so we manually reindex
  [Project, Post, Resource, User].each do |klass|
    klass.__elasticsearch__.import(force: true)
  end

  sleep 2 # Rebuilding the index takes a second or two
end
```

An example test:

```
before do
  create_list(:list, 1, title: "Vermont Bridges", private: false)
  create_list(:list, 3, title: "Pretty Churches", caption: "Near Covered Bridges", private: true)
  create_list(:list_item, 5, list: List.first, title: "Covered Bridges Tour")
  create_list(:list_item, 7, list: List.first, caption: "Pretty Church")

  reindex_elasticsearch!
end

it "can search Lists" do
  expect(List.count).to eq 4
  expect(List.__elasticsearch__.search("*vermont*").results.total).to eq 1
  # is case insensitive
  expect(List.__elasticsearch__.search("*VeRmOnT*").results.total).to eq 1
  expect(List.__elasticsearch__.search("*church*").results.total).to eq 3
  expect(List.__elasticsearch__.search("*").results.total).to eq 4
end

it "can search across multiple models" do
  search = Elasticsearch::Model.search("*church*")
  expect(search.results.total).to eq 10

  num_lists = search.results.select{ |r| r._index.match /lists$/ }.count
  num_list_items = search.results.select{ |r| r._index.match /list-items$/ }.count
  expect(num_lists).to eq 3
  expect(num_list_items).to eq 7
end

it "can paginate results" do
  search = ListItem.__elasticsearch__.search("*").per(10).page(1)
  expect(search.results.count).to eq 10
  expect(search.results.total).to eq 12
end

it "can perform custom DSL searches" do
  search = List.__elasticsearch__.search("*bridge*")
  expect(search.results.count).to eq 4

  # search a specific field
  search = List.__elasticsearch__.search({query: {match: {caption: "bridges"}}})
  expect(search.results.count).to eq 3

  # search multiple fields
  search = List.__elasticsearch__.search({query: {multi_match: {
    fields: ["title", "caption"],
    query: "bridges"}}})
  expect(search.results.count).to eq 4

  # fuzzy terms (detects inexact matches)
  search = List.__elasticsearch__.search({query: {multi_match: {
    fields: ["title", "caption"],
    query: "bridge",
    fuzziness: "AUTO"}}})
  expect(search.results.count).to eq 4

  # filter by condition
  public_matches = List.__elasticsearch__.search({filter: {term: {private: "false"}}})
  expect(public_matches.results.count).to eq 1

  # Muli-model searches can support fuzziness and specific fields too
  # TODO
end
```
