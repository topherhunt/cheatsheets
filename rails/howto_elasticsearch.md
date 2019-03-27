# ElasticSearch integration with Rails

This was extracted from my latest rewrite of ElasticSearch indexing & searching integration w Thriveability Lab.

Notes on the approach:

- I'm only using the low-level `elasticsearch` driver because a non-trivial searching setup with `elasticsearch-rails` turned out to need a lot of gluework and overrides to make it performant and easy to introspect. In fact, rewriting all the searching & indexing logic from scratch turned out to be less code (and easier to follow) than all the workaround code.
- On Heroku Bonsai Elasticsearch the # of shards is strictly limited. This approach let me index all records on a single index, meaning I can more easily limited shard proliferation.
- Indexing all models in a single index meant that the index mapping can't be very specific to the shape of the searched models, but actually I prefer that. I defined some generic fields `full_text_primary` and `full_text_secondary`, and can add more as needed.


## Installing it

Install ES for local dev if you don't already have it. On OSX, just do `brew install elasticsearch`, then start the server by running `elasticsearch` in a new tab.

Add just the low-level driver to your Gemfile. We don't even need the `bonsai-elasticsearch` gem; all that gem does is configure the ES client to use the special `BONSAI_URL` env var.

```ruby
gem 'elasticsearch'
```

Configure `ENV["ELASTICSEARCH_URL"]` to point to the ES server, and make that env var required. e.g.:

```
# in application.yml

development:
  ELASTICSEARCH_URL: http://localhost:9200

production:
  ELASTICSEARCH_URL: https://someUN:somePW@maple-123.us-east-1.bonsaisearch.net
```

Configure development to disable auto-indexing if ES isn't reachable:

```ruby
# config/initializers/elasticsearch.rb
if Rails.env.development?
  begin
    # Verify that Elasticsearch is running and reachable
    ElasticsearchWrapper.new.check_health
  rescue Faraday::ConnectionFailed => e
    msg = "WARNING: Elasticsearch isn't reachable; disabling indexing."
    Rails.logger.warn(msg)
    puts msg
    ENV['ES_INDEXING_DISABLED'] = 'true'
  end
end
```

In the global test setup, disable auto-indexing for all tests:

```ruby
ENV['ES_INDEXING_DISABLED'] = 'true'
```

ElasticsearchWrapper handles all low-level ES calls:

```ruby
# app/logic/elasticsearch_wrapper.rb
# ElasticSearch low-level wrapper. Knows about our global index and field mappings,
# but doesn't know anything about ActiveRecord, what models are indexed, how to
# search, etc.
#
class ElasticsearchWrapper
  def check_health
    client.cluster.health # If no exceptions, that means it's connected
  end

  # See https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html
  def create_index
    run(:put, index_name, body: {
      # Start with 1 shard, and add more as content grows.
      # See https://www.elastic.co/blog/how-many-shards-should-i-have-in-my-elasticsearch-cluster
      settings: {index: {number_of_shards: 1}},
      # See https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html
      mappings: {
        doc: { # Use 'doc' as our sole mapping type (a soon-to-be-deprecated concept)
          dynamic: "strict", # Disable dynamic mapping (it's on by default)
          properties: standard_field_mappings
        }
      }
    })
    log :info, "Created index #{index_name}"
  end

  def delete_index
    if index_exists?
      run(:delete, index_name)
      log :info, "Deleted index #{index_name}"
    else
      log :info, "Index #{index_name} not found, so not deleted."
    end
  end

  def list_indexes
    run(:get, "_aliases").keys
  end

  def index_exists?
    list_indexes.include?(index_name)
  end

  def index_document!(id, body) # The id can be any arbitrary string
    run(:put, "#{index_name}/doc/#{id}", body: body)
    log :info, "Indexed document #{id}"
  end

  def delete_document(id)
    if run(:delete, "#{index_name}/doc/#{id}", allow_404: true)
      log :info, "Deleted document #{id}"
    else
      log :warn, "Unable to delete document #{id}, got a 404 error"
    end
  end

  def count_documents
    run(:get, "#{index_name}/_count").fetch("count")
  end

  def search(body)
    run(:get, "#{index_name}/_search", body: body)
  end

  #
  # Internal
  #

  def index_name
    @index_name ||= "thriveability-#{Rails.env}-global"
  end

  # Full delete & reindex will be needed if I change the mappings
  def standard_field_mappings
    {
      class: {type: "keyword"},
      id: {type: "integer"},
      full_text_primary: {type: "text"}, # for boosted text, e.g. title & tags
      full_text_secondary: {type: "text"} # for unboosted text, e.g. description
      # For now I only set up fields for plain full-text search (one boosted
      # field & one unboosted), but we can also add structured fields, e.g.:
      # - limit results to those having a tag (keyword multivalue field)
      # - filter results by region / proximity (geo point)
    }
  end

  def run(method, path, body: {}, allow_404: false)
    method = method.to_s.upcase
    response = client.perform_request(method, path, {}, body).body.as_json
    # log :debug, "REQUEST: #{method} #{path} #{body.to_json}. RESPONSE: #{response.to_json}"
    response
  rescue => e
    if allow_404 && e.to_s.include?("[404]")
      false
    else
      raise "ElasticsearchWrapper#run failed on #{method} #{path} "\
        "(body: #{body.to_json}). ERROR: #{e}."
    end
  end

  def client
    @client ||= Elasticsearch::Client.new(
      url: ENV.fetch('ELASTICSEARCH_URL'),
      # log: true, # Might be useful when debugging
      # I think this was a development-friendly option, I'll try skipping it
      # transport_options: {request: {timeout: 5}}
    )
  end

  def log(sev, message)
    sev.in?([:info, :warn, :error]) || raise("Unknown severity '#{sev}'!")
    Rails.logger.send(sev, "#{self.class}: #{message}")
  end
end
```

ElasticsearchIndexHelper manages high-level indexing operations:

```ruby
# app/logic/elasticsearch_index_helper.rb
# ElasticSearch high-level indexing helper.
class ElasticsearchIndexHelper
  SEARCHABLE_CLASSES = [User, Project, Conversation, Resource]

  def delete_and_rebuild_index!
    wrapper.delete_index
    wrapper.create_index
    num_indexed = 0
    SEARCHABLE_CLASSES.each do |klass|
      # NOTE: If I need to do large-scale full reindexing often, consider
      # setting up batch-import to reduce the # of ES calls used.
      # (see elasticsearch-rails .import(force: true), it did this well)
      klass.all.find_each { |r| create_document(r); num_indexed += 1 }
    end
    verify_new_documents_ingested(num_indexed)
  end

  def verify_new_documents_ingested(num_to_expect)
    waited = 0
    while wrapper.count_documents < num_to_expect
      sleep 0.1
      waited += 0.1
      raise "Waited too long for indexed docs to be digested!" if waited >= 5
    end
  end

  def create_document(record)
    wrapper.index_document!(document_id(record), document_body(record))
  end

  def update_document(record)
    wrapper.index_document!(document_id(record), document_body(record))
  end

  def delete_document(record)
    wrapper.delete_document(document_id(record))
  end

  private

  def wrapper
    @wrapper ||= ElasticsearchWrapper.new
  end

  def document_id(record)
    "#{record.class.to_s}:#{record.id}"
  end

  def document_body(record)
    {class: record.class.to_s, id: record.id}.merge(record.to_elasticsearch_document)
  end

  def log(sev, message)
    sev.in?([:info, :warn, :error]) || raise("Unknown severity '#{sev}'!")
    Rails.logger.send(sev, "#{self.class}: #{message}")
  end
end
```

Searchable concern for model indexing integration:

```ruby
# app/models/concerns/searchable.rb
# Include this in any model to include it in Elasticsearch indexing & search.
# The model must also implement #to_elasticsearch_document to return a hash
# of the index document, e.g. {full_text_primary: "The title etc."}
module Searchable
  extend ActiveSupport::Concern

  included do
    after_create :create_es_document
    after_update :update_es_document
    after_destroy :delete_es_document

    def create_es_document
      return if es_autoindexing_disabled?
      ElasticsearchIndexHelper.new.create_document(self)
    end

    def update_es_document
      return if es_autoindexing_disabled?
      # TODO: Skip update if no indexed fields are changed
      ElasticsearchIndexHelper.new.update_document(self)
    end

    def delete_es_document
      return if es_autoindexing_disabled?
      ElasticsearchIndexHelper.new.delete_document(self)
    end

    def es_autoindexing_disabled?
      ENV['ES_INDEXING_DISABLED'] == 'true'
    end

    def to_elasticsearch_document
      raise "#{self.class} must implement #to_elasticsearch_document!"
    end
  end
end
```

Set up each searchable model:

```ruby
# example user.rb
class User < ApplicationRecord
  include Searchable

  ...

  def to_elasticsearch_document
    {
      full_text_primary: [name].join(" "),
      full_text_secondary: [tagline, interests, location, bio].join(" ")
    }
  end
end
```

RunSearch service which runs a full-text query given a search string:
(BaseService follows my `services` pattern)

```ruby
# app/services/run_search.rb
class RunSearch < BaseService
  def call(classes: [], string:, from: 0, size: 100)
    query = build_query(
      classes: validate_classes(classes), # each must be a string
      string: string,
      from: from,
      size: size)
    @response = ElasticsearchWrapper.new.search(query)
    @total = @response["hits"].fetch("total")
    log :info, "Ran search: #{query.to_json}. #{@total} results."
    self
  end

  #
  # Helpers for inspecting & loading the results
  #

  attr_reader :total, :response

  def identifiers
    @identifiers ||= @response["hits"]["hits"].map do |hit|
      source = hit.fetch("_source")
      [source.fetch("class"), source.fetch("id")]
    end
  end

  # Batch-load each result's record if it exists. NOT memoized.
  # Return them in an array preserving the search result order.
  def loaded_records
    classes = identifiers.map(&:first).uniq.sort
    records = classes.map do |klass|
      # We don't assume that each id can currently be found in the database
      # (some results might be orphaned references to deleted records)
      klass.constantize.where(id: ids_in_class(klass)).all
    end.flatten
    identifiers.map do |(klass, id)|
      records.find { |r| r.class.to_s == klass && r.id == id } # may be nil
    end.compact
  end

  #
  # Internal helpers
  #

  def ids_in_class(target_class)
    identifiers
      .select { |(c, id)| c == target_class }
      .map { |(c, id)| id }
  end

  def validate_classes(classes)
    classes = classes.count >= 1 ? classes : all_searchable_classes
    classes.each do |c|
      unless c.in?(all_searchable_classes)
        raise "Invalid class value #{c.inspect}. Valid values: #{all_searchable_classes}"
      end
    end
    classes
  end

  def all_searchable_classes
    ElasticsearchIndexHelper::SEARCHABLE_CLASSES.map(&:to_s)
  end

  def build_query(classes:, string:, from:, size:)
    {
      query: {
        bool: {
          filter: [{terms: {class: classes}}],
          must: [match_string_if_present(string)]
        }
      },
      sort: [{_score: "desc"}],
      from: from,
      size: size
    }
  end

  def match_string_if_present(string)
    if string.present?
      {
        multi_match: {
          query: string,
          fields: %w(full_text_primary^3 full_text_secondary^1),
          operator: "and",
          fuzziness: "AUTO" # (default) allows near-matches
        }
      }
    else
      {match_all: {}}
    end
  end
end
```

The SearchController et al. can call RunSearch like so:

```ruby
search = RunSearch.call(
  classes: [], # will default to all
  string: "kittens",
  from: 20,
  size: 10)
search.total # => 39
search.loaded_records # => array of AR records, ordered by search ranking
```

RunSearchTest gives you end-to-end coverage of indexing content (but not auto-indexing), executing various search queries, and parsing the results:

```ruby
# test/services/run_search_test.rb
require "test_helper"

class RunSearchTest < ActiveSupport::TestCase
  def assert_results_equal(result, expected)
    # First compare the identifiers
    assert_equals(
      Set.new(expected.map { |e| [e.class.to_s, e.id] }),
      Set.new(result.identifiers))
    # Then also check loaded_records, just as a sanity check
    assert_equals(
      Set.new(expected),
      Set.new(result.loaded_records))
  end

  test "elasticsearch integration works w all kinds of searches" do
    # These tests are grouped into one example to minimize ES reindexing time.
    @user1 = create :user, name: "A person who likes apple pie"
    @project1 = create :project, title: "Apple farming in urban parks"
    @project2 = create :project, title: "Another, irrelevant project"
    @resource1 = create :resource, title: "A resource about apples"
    @resource2 = create :resource, title: "A second, irrelevant resource"
    @convo1 = create :conversation, title: "This conversation is about apples"
    @convo2 = create :conversation, title: "A second conversation"
    @convo3 = create :conversation, title: "A third, irrelevant conversation"
    create :comment, context: @convo2, body: "Apples are important to this comment"

    assert_elasticsearch_running
    ElasticsearchIndexHelper.new.delete_and_rebuild_index!

    # a broad search returning all kinds of content
    result = RunSearch.call(string: "apple")
    assert_equals 5, result.total
    assert_results_equal(result, [@user1, @project1, @resource1, @convo1, @convo2])

    # a blank search (match all)
    result = RunSearch.call(string: "")
    assert_equals 16, result.total

    # a search with no results
    result = RunSearch.call(string: "gobbledygook")
    assert_equals 0, result.total
    assert_equals [], result.loaded_records

    # a paginated search
    all_results = RunSearch.call(string: "").identifiers
    page3_results = RunSearch.call(string: "", from: 6, size: 3)
    assert_equals 16, page3_results.total
    assert_equals 3, page3_results.identifiers.count
    assert_equals all_results[6..8], page3_results.identifiers

    # a search that limits based on result type
    result = RunSearch.call(string: "", classes: ["Project", "Resource"])
    assert_equals 4, result.total
    expected = [@project1, @project2, @resource1, @resource2]
    assert_results_equal result, [@project1, @project2, @resource1, @resource2]
  end
end
```

Finally update the readme to note some ES usage logistics:

```
### ElasticSearch

This app uses ElasticSearch as a simple search index. See `ElasticsearchWrapper`, `ElasticsearchIndexHelper`, and `Searchable`.

- In development, run `elasticsearch` or indexing & searching will be disabled. (`brew install elasticsearch`)
- In production, we use the Bonsai Heroku add-on, but any ES server will work as long as we provide the full URL in `ENV['ELASTICSEARCH_URL']`.
- Run do a full reindex on setup and any mapping changes: `ElasticsearchIndexHelper.new.delete_and_rebuild_index!`
```


## Periodic full reindex

This code relies on the Rails model callbacks to keep the index up-to-date. Scripted batch operations or ill-timed exceptions could easily cause the ES index to get out-of-sync with what's in the live database. That might result in a) orphaned documents that point to deleted records, and b) important records in the db that don't have an entry in the ES index.

The solution would be to periodically run a full reindex (in addition to the current model-callback-triggered object-specific index updates). This code doesn't provide a routine task for full reindexing, but it wouldn't be too hard to add. It would probably involve:

1. Write a non-destructive reindexer that loops over all existing db content and upserts the document for each, but doesn't delete & recreate the full index. It's important that it not delete the index, and only upsert existing content, so that concurrent searches won't be borked.

2. On index_document, set a ttl so the document will expire after a period longer than the full reindexing period. So e.g. current documents' TTLs will be updated daily (assuming daily full reindexing) but orphaned documents that point to deleted records will expire after a week.



## Manually querying ES

Run manual test queries against ES using Postman or similar. No need for a dedicated ES querying GUI. Some example ES queries I saved in Postman:

```bash
# Get cluster settings
GET http://localhost:9200/

# List all shards, grouped by index
GET http://localhost:9200/_shard_stores

# List all indexes
GET http://localhost:9200/_aliases

# Get settings & mappings for an index
GET http://localhost:9200/thriveability-development-global/

# Delete an index
DELETE http://localhost:9200/gf-test-circles

# Run a query against one index
GET http://localhost:9200/thriveability-test-global/_search
# with json body:
{
  "query": {
    "bool": {
      "filter": [
        {"terms": {"class": ["User", "Project", "Conversation", "Resource"]}}
      ],
      "must": [{"match_all": {}}]
    }
  },
  "sort": [{"_score": "desc"}],
  "from": 0,
  "size": 100
}
```
