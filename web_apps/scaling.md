# Scaling a web app


## Requests per second / month / etc.

Some orienting benchmarks on RPS:

- Per Scout APM's pricing benchmarks, a "small" app serves up to 2 rps (167k requests / day). A "large" app serves up to 8 rps.

- Per Datadog as of 2019-04, GlassFrog serves avg ~3 rps (240k requests / day).
  - Keep in mind the actual rps can be way higher (10x?) during traffic spikes.
  - This number might make GF's popularity appear inflated due to our heavy use of GUPS which could trigger 50+ ajax requests for a single page request. (Migrating to Relay will mostly fix this.)

- 70 rps (6m requests / day) is considered an impressive amount of traffic for a small company.

- AppSignal APM would cost €500/month for that traffic volume. Scout APM's largest plan only supports 10% of that volume. So this is considered a "big" app.
