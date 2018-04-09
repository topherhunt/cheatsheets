## Searching

A basic search:

```
# Always pass an ES query hash, not just a string.
response = Elasticsearch::Model.search(
  {query: {match: {title: "fox"}}},
  [Model1, Model2] # specify which models to include in the search
)
response.results # returns an array of Hashie JSON results
response.results.total
response.results.first._source
response.records # load the ActiveRecord objects into an array
# Warning: `response.records` returns objects of proxy classes, so `record.class`
# is NOT equivalent to the model class that it appears to be.
```

A more complex multi-field search:

```
Elasticsearch::Model.search(
  query: {
    multi_match: { # match terms across many or all fields
      query: "bear apple",
      # Looks at all fields by default. Do NOT set `fields: ["*"]`, that's buggy.
      operator: "or", # default is "and" (more restrictive)
      fuzziness: "AUTO" # (default) Allows near matches
    }
  },
  highlight: {fields: {title: {}}},
  [Model1, Model2]
)
```

Other search options:

- Return all records: `{query: {match_all: {}}}` or `{}`
- Use `bool` query type to combine subqueries (e.g. require a `multi_match` and also limit results to documents matching a specific `term`)
- Use `from` and `size` to paginate

## Excluding documents from search

You can manually implement the indexing callbacks instead of using `Elasticsearch::Model::Callbacks`, but because a record may switch between indexable and un-indexable throughout its lifespan, this approach is fraught. Instead, in each document's indexed json, include a `visible` field that you can filter by like this:

```
{
  "query": {
    "bool": {
      "filter": [
        {"term": {"visible": "true"}}
      ],
      "must": [
        ... your normal match queries ...
      ]}}}
```

Any documents where `visible` is `false` (or where the field is absent!) will be excluded from results.

## Low-level queries & calls

```
client = Elasticsearch::Client.new(log: true)
response = client.perform_request('GET', '_aliases')
response.as_json['body'].keys.sort
# => ["ic-development-posts", "ic-development-resources", ...]

response = client.search({index: "index1,index2", body: the_query})
response.as_json['hits']['hits']
# => the same JSON hash as is returned by Elasticsearch::Model.search
```

## Configuration

- By default, ES uses the standard tokenizer which doesn't perform stemming, meaning that only whole terms (or near matches, if fuzziness is enabled) will be matched in a search. To also search partial terms or word stems, see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/analysis-analyzers.html and https://www.elastic.co/guide/en/elasticsearch/guide/current/_controlling_analysis.html.
- Inspect an index's current configuration by going to `http://localhost:9200/ic-test-users/_settings` and `http://localhost:9200/ic-test-users/_mapping`.
- Configure your `elasticsearch` server using `elasticsearch.yml`, which lives at the config file specified in the "JVM arguments" line when starting up ES.

## Troubleshooting

- Add `"explain": true` above your main `"query":` node to output score calculation explanations. (This is verbose.)

Other useful diagnostic commands:

```
Article.__elasticsearch__.client.cluster.health
Project.__elasticsearch__.client.indices.get_mapping
Article.__elasticsearch__.search("abc").results.first._index # => "pangeo-development-lists"
```
