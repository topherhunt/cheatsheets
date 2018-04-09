# Model-level ElasticSearch integration

(from Integral Climate)

## The Elasticsearch service

In development, `brew install elasticsearch` then I can run `elasticsearch` to start the local server.

In production, use a managed ES service like Bonsai (for Heroku). Never do self-managed ES.

## Install the gems

```
# Gemfile
gem 'elasticsearch-model'
gem 'bonsai-elasticsearch-rails' # if deploying to Heroku
```

- `bundle install`

## Configure the gem

```
# config/initializers/elasticsearch.rb
# In production, use the config provided by bonsai-elasticsearch-rails.
unless Rails.env.production?
  Elasticsearch::Model.client = Elasticsearch::Client.new(
    host: "http://localhost:9200",
    transport_options: {
      request: {timeout: 5}
    }
  )
end
```

## Add search capabilities to each model

```
# app/models/post.rb
class Post

  ...

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks # auto-updates index on changes
  __elasticsearch__.index_name "ic-#{Rails.env}-posts"

  ...

  def as_indexed_json(options={}) # ES index definition - defaults to .as_json()
    {
      title: title,
      published_content: published_content,
      author_name: author.full_name,
      tags: tag_list.join(", "),
      visible: root_and_published? # Every ES record should have a :visible field
    }
  end
```

## Add a search wrapper class

```
# app/services/searcher.rb
class Searcher
  SEARCHABLE_MODELS = [User, Project, Post, Resource]
  # See https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-multi-match-query.html#_literal_fields_literal_and_per_field_boosting
  SEARCHABLE_FIELDS = %w(full_name^3 title^3 tagline^1.5 subtitle^1.5 interests description location bio_interior bio_exterior current_url source_name tags media_types published_content author_name descendants^0.5 introduction stage)

  # Creates the index if missing. Truncates all old content.
  def self.rebuild_es_index!
    unless `ps aux | grep elasticsearch | grep java | grep -v grep`.present?
      raise "`elasticsearch` doesn't seem to be running."
    end

    SEARCHABLE_MODELS.each { |model| model.__elasticsearch__.import(force: true) }
    sleep 2 # Give ES time to finish indexing
  end

  def initialize(string:, models: nil, from: 0, size: 100)
    @string = string
    @models = models || SEARCHABLE_MODELS
    @from = from
    @size = size
    raise "Result window is too large for ES to handle!" if (@from + @size) > 10000
  end

  def run
    Rails.logger.info "ElasticSearch query against #{@models.map(&:to_s)}: #{query.to_json}"
    Elasticsearch::Model.search(query, @models)
  end

  def query
    {
      query: {
        bool: {
          filter: [
            {term: {visible: true}}
          ],
          must: [
            (@string.present? ? match_string : match_all_documents)
          ]
        }
      },
      from: @from,
      size: @size
    }
  end

  def match_string
    {
      multi_match: {
        query: @string,
        fields: SEARCHABLE_FIELDS,
        operator: "and", # all words in the search string must be matched
        fuzziness: "AUTO" # (default) allows near-matches
      }
    }
  end

  def match_all_documents
    {
      match_all: {}
    }
  end
end
```

## Add tests for the wrapper class

```
# test/models/searcher_test.rb
require "test_helper"

class SearcherTest < ActiveSupport::TestCase

  def debug(records)
    records.map { |r| "#{r.class}: #{r.try(:title) || r.full_name}" }
  end

  setup do
    @user1 = create :user, first_name: "Mackenzie", last_name: "Platypus"
    @project1 = create :project, title: "Omnivore's Dilemma"
    @resource1 = create :resource, title: "Mackenzie's Study"
    @post1 = create :published_post, title: "Platypus is an Omnivore"
    @post2 = create :published_post, title: "My study of Omnivores"
    @draft = create :draft_post
    @comment = create :published_post, parent: @post2
    Searcher.rebuild_es_index!
  end

  it "searches across all indexed models by default" do
    search1 = Searcher.new(string: "omniVORE").run
    expected1 = [@project1, @post1, @post2]
    assert_equals debug(expected1).sort, debug(search1.records).sort

    search2 = Searcher.new(string: "mackenzie").run
    expected2 = [@user1, @resource1]
    assert_equals debug(expected2).sort, debug(search2.records).sort

    search3 = Searcher.new(string: "Beelzebub").run
    assert_equals 0, search3.records.count
  end

  it "includes all results when query is blank" do
    search_all = Searcher.new(string: "").run
    assert_equals 11, search_all.count
  end

  it "can limit results to specific models" do
    search = Searcher.new(string: "study", models: [Resource]).run
    expected = [@resource1]
    assert_equals debug(expected).sort, debug(search.records).sort
  end

  it "can paginate results" do
    search_all = Searcher.new(string: "").run
    assert_equals 11, search_all.count

    search1 = Searcher.new(string: "", from: 0, size: 10).run
    assert_equals 10, search1.count
    assert_equals debug(search_all.records[0..9]), debug(search1.records)

    search2 = Searcher.new(string: "", from: 10, size: 10).run
    assert_equals 1, search2.count
    assert_equals debug(search_all.records[10..-1]), debug(search2.records)
  end

  it "returns published posts, but not drafts or comments" do
    draft = create :draft_post
    search_posts = Searcher.new(string: "", models: [Post]).run
    expected = [@post1, @post2]
    assert_equals debug(expected).sort, debug(search_posts.records).sort
  end

  it "SEARCHABLE_FIELDS contains a list of all indexed fields" do
    known_fields = Searcher::SEARCHABLE_FIELDS.map { |f| f.sub(/[\^\d\.]+/, "") }
    known_but_ignored = ["visible", "owner"]

    [
      create(:user),
      create(:published_post),
      create(:project),
      create(:resource)
    ].each do |record|
      record.as_indexed_json.keys.map(&:to_s).each do |field|
        next if field.in?(known_but_ignored)
        unless field.in?(known_fields)
          raise "#{record.class} indexed field '#{field}' isn't included in Searcher::SEARCHABLE_FIELDS! Fix it or the field will be excluded from ES queries."
        end
      end
    end
  end
end
```

## Update README.md with basic usage hints

```
## ElasticSearch

We use ElasticSearch as our search index. See the `elasticsearch-model` gem docs for more detail. On Heroku, ES is served via the Bonsai Elasticsearch add-on. In development, use the Homebrew `elasticsearch` package.

Useful commands:
- `Searcher.rebuild_es_index!`
- `Project.__elasticsearch__.search('psychology')`
- `Project.__elasticsearch__.search({query: SOME_LONG_ES_QUERY})`
- `Project.__elasticsearch__.client.cluster.health`
```

## Use it!

- Run `elasticsearch` (from Brew or wherever)
- `Searcher.rebuild_es_index!`
- Tests should pass
