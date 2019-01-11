# Web app production-readiness checklist

* Customers' bug reports and help requests go directly to the webmaster, so that we feel their pain immediately and have high motivation to eliminate any problems they encounter

* (if Rails) Bullet gem is configured to raise in dev & test if lazy-loaded N+1 queries are detected (forcing us to preload associated data up-front)

* The readme contains:
  - Overview of the purpose & main components of the app
  - Overview of code style guidelines (test suite principles etc.)
  - How to set up for local development & testing
  - How to do load testing
  - How to safely deploy changes
  - Notes on our production environment:
    * where to find stuff
    * how to deploy changes
    * how to scale up & down to accommodate traffic, etc.
  - How to deploy to a new prod environment
  - A link to this production-readiness checklist

Database:

  * DB is auto backed upn on a regular basis

  * DB migrations are small, focused, and safe against table locking risks (see https://github.com/LendingHome/zero_downtime_migrations) unless downtime is expected

Testing:

  * Test suite covers all business-critical behavior.

  * All tests are passing with network access disabled.

  * Load-testing harness that makes it easy to assess how the current deployment will stand up to various amounts of traffic

Logging:

  * Production app logs 1 line per request, containing: the timestamp, request method, URL, params, time taken, response status, redirected_to (if redirected), and current logged-in user id + name.

  * In production, don't log individual SQL queries, templates rendered, email body content, or other junk.

  * All timestamps in all logging & other analytics are in UTC.

Monitoring:

  * UptimeRobot pings every 5m and alerts the webmaster if /health is unreachable (every 24h if it's on Heroku free tier). This health-check endpoint makes a trivial DB call to ensure we have db access.

  * Webmaster is sent a regular digest of # of email failures (e.g. weekly) so that dropped / blocked emails don't go unnoticed. (or alert webmaster via Lambda webhook on each failure)

  * APM is set up (e.g. Skylight) so webmaster can monitor traffic patterns and identify needed performance improvements

  * Webmaster is auto-alerted when there's heavy traffic or slow response times, and has an easy pathway to scaling up server resources to meet demand

  * Error reporting set up (e.g. Rollbar); webmaster is alerted on any server errors

Compliance:

  * The production app is nominally GDPR-compliant (all emails are sent from within the EU; logs are stored within the EU; logs are cleared after 30 days)
