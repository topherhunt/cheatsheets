# Caching

TO INCORPORATE: DHH's advice on key-based cache expiration: https://signalvnoise.com/posts/3113-how-key-based-cache-expiration-works - this lets you mostly avoid the problem of cache invalidation.


## General checklist for caching layer

- Debug-log every cache hit, miss (log how long it took to recalculate each), and bust (log the pattern, plus every specific cache key busted)
- Clear the cache on every app init (and log this)
- Clear the cache before every test
- Keep cache keys as high-level as possible, to avoid "N+1 caches" problem. Ideally any request should only interact with a small handful of caches.


## Rule: Avoid N+1 caches. Scope cache keys to one global resource ID.

When caching expensive values, it's tempting to define highly specific cache keys that target a specific sub-resource ID, e.g. `user_[ID]_project_[ID]_name_with_ancestry`. While this is technically the most efficient way to cache data, this strategy leads to a proliferation of cache keys at different layers of specificity. With so many different caches flying around, it gets harder to manage them, expire them correctly, debug problems, and even understand how they interact. In other words: the more cache keys your app manages, the greater the developer pain of managing the caching layer.

In some ways, this is similar to the N+1 query problem, and I recommend solving it in the same way: intelligently batch your caches. Keep them at the highest level of granularity than you can without losing the performance benefits. Define your cache keys using only one, consistent top-level resource identifier; avoid defining separate cache keys for specific sub-resources.

For me, in many of my apps, that means the cache key contains a `user_id` or an `organization_id` (whatever is the best top-level bucket for the domain model) and no other variables in the key name.

For example, instead of having highly resource-specific (and highly efficient) cache keys like `user_[ID]_project_[ID]_name_with_ancestry`, I'd instead err towards a per-user "map cache" like `user_[ID]_projects_name_with_ancestry_map`.

Implications of this strategy:

- Any HTTP request should only reference a small, predictable number of cache values.
- The number of cache interactions becomes comparable to the number of SQL queries. (Assuming you don't have any "N+1 query" problems.)
- Because there's so much fewer cache interactions, you can debug-log every cache hit and miss in the same way you debug-log your SQL queries, making it easier to troubleshoot caching problems in a methodical way.
- Makes it easier to reason about what's cached, when it's expired, and what went wrong
- This is technically more wasteful than highly specific caches. You'll need to rebuild more redundant data this way. But my experience is that I still get most of the performance benefits of caching expensive stuff, but with way less of the complexity.


## Other notes on caching strategy

- DON'T try to be programmatic or clever about determining what caches to bust. Instead, each updater function (eg. the insert & update functions in the context) should manually have commands to bust any relevant caches.
- DO bust swaths of caches where convenient.
- DON'T do eager cache warming. Lazy warming makes it way easier to think through the performance implications, and makes busting a swath of caches more appealing.
