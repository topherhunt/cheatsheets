# GraphQL, Absinthe, & Apollo

Here are tips for writing GraphQL apis and consumers. Focused on using Absinthe (server-side) and Apollo (client-side).


## References

Absinthe intro tutorial (fantastic):

  * https://hexdocs.pm/absinthe/start.html
  * (continue learning at: https://hexdocs.pm/absinthe/query-arguments.html)

Apollo React client intro tutorial:

  * https://www.apollographql.com/docs/react/essentials/get-started

Other resources:

  * https://github.com/absinthe-graphql/absinthe_tutorial
  * https://schneider.dev/blog/elixir-phoenix-absinthe-graphql-react-apollo-absurdly-deep-dive/

Authentication & Contexts:

  * https://hexdocs.pm/absinthe/plug-phoenix.html#absinthe-context


## Apollo

Best practices:

  * Don't write GQL queries directly in components. Instead define all queries in a queries.js and import the relevant query in the component where you need it. This makes it easier to reuse your queries, e.g. when doing manual update after a mutation.

Mutations:

  * On most create/delete mutations, you'll need to manually tell Apollo how to update the cache. (The cache is synced automatically for most updates to already-cached records.) You do this by providing an updater function to the Mutation component. See https://www.apollographql.com/docs/react/essentials/mutations#update for the basics.

  * Your updater works by querying the cache, transforming the returned data, then writing that updated data back to the cache.

  * Your updater function MUST use the same query(ies) that you want to update the cache data for. Resist the temptation to define an updater query that only fetches the relevant fields from the cache. This makes it too easy to forget associations, inviting subtle bugs.

  * Depending on your package versions, even if you provide an updater function that writes the updated data to the cache, Apollo might not realize that a rerender is needed if the top-level objects aren't changed. So if your only cache changes are deeply nested, you should also touch an unused top-level field, like this: (more discussion: https://github.com/apollographql/react-apollo/issues/2099, https://github.com/apollographql/apollo-client/issues/2415)

```
cachedData.touchCache = Math.random() // help Apollo realize that a rerender is needed
```

  * For more options re: updating the cache after mutations, see https://www.apollographql.com/docs/react/advanced/caching/.


## Troubleshooting

  * It's easy to introduce typos into your Absinthe types & resolvers, and it often won't warn you. If your query return suspicious `null`s, double-check your Types for incorrectly specified resolve functions etc.

  * Sometimes Absinthe blows up with a resolver-related error, but the stacktrace doesn't mention any of your files. You can often find the source by making a progressively more tightly-scoped GQL query until you can identify what field it's blowing up on.

  * Similarly, Apollo won't warn you if your query references e.g. `target_id` instead of `targetId`. So if you notice nulls for certain returned fields, double-check that you're camelCasing properly.
