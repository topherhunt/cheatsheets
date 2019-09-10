# Web app production-readiness checklist

* Customers' bug reports and help requests go directly to the webmaster, so that we feel their pain immediately and have high motivation to eliminate any problems they encounter

* (if Rails) Bullet gem is configured to raise in dev & test if lazy-loaded N+1 queries are detected (forcing us to preload associated data up-front)

* The readme contains everything in my `readme_template.md`

Security:

  * All file upload vectors are validated for attachment size, or post-processed to protect against huge images, as relevant

  * Changesets have validations for all conceivable string & numeric field exploits (e.g. registering a 2000-char username or setting your age to 9999999999999999 should not result in a database error!)

Database:

  * DB is auto backed up regularly

  * DB migrations are small, focused, and safe against table locking risks (see https://github.com/LendingHome/zero_downtime_migrations) unless downtime is expected

Test coverage:

  * Controllers: tests for all endpoints, & all possible logic pathways for each

  * Integration: judicious test coverage for all important happy paths

  * Contexts: tests for all schema inserts, covering all conceiveable field edge cases & ensuring that the error messages look sane (e.g. what if they register with a 2k-char username? what if they set their age to 99999999999?)

  * Custom logic modules: all complex logic has judicious unit test coverage

  * All tests pass reliably with network access disabled

Performance:

  * Any api endpoints that return collections are paginated (unless there's a good reason why they won't need pagination).

  * Page loads reviewed. (target under 100KB for most pages)

  * Load-testing script set up. (K6?) The site can comfortably handle 10x projected traffic.

Logging:

  * Log 1 line per request, containing: the timestamp, request method, URL, params, time taken, response status, redirected_to (if redirected), and current logged-in user id + name.

  * Log thorough details on each email being sent out, e.g. "Sending mail AssessmentMailer.ready_for_stem_scoring ("MAP ID # 103 is ready for scoring") to scorer@example.com" (see MAPP as example)

  * In production, don't log individual SQL queries, templates rendered, email body content, or other junk.

  * All timestamps in all logging & other analytics are in UTC.

Monitoring:

  * Error reporting set up (e.g. Rollbar); webmaster is alerted on any server exceptions **or error log statements**

  * Google Analytics

  * UptimeRobot pings every 5m and alerts the webmaster if /health is unreachable (every 24h if it's on Heroku free tier). This health-check endpoint makes a trivial DB call to ensure we have db access.

  * Webmaster is sent a regular digest of # of email failures (e.g. weekly) so that dropped / blocked emails don't go unnoticed. (or alert webmaster via Lambda webhook on each failure)

  * APM is set up (e.g. Skylight) so webmaster can monitor traffic patterns and identify needed performance improvements

  * Webmaster is auto-alerted when there's heavy traffic or slow response times, and has an easy pathway to scaling up server resources to meet demand

Compliance:

  * The production app is nominally GDPR-compliant (all emails are sent from within the EU; logs are stored within the EU; logs are cleared after 30 days)
