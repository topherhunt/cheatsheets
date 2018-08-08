# Web app production-readiness checklist

* Production app logs 1 line per request, containing: the timestamp, request method, URL, params, time taken, response status, and current logged-in user id & name.
* In production, don't log individual SQL queries, templates rendered, email body content, or other junk.
* UptimeRobot pings every 5m and alerts the webmaster if /health is unreachable (unless it's on Heroku free tier).
* Webmaster is sent regular digest of # of email failures (e.g. weekly) so that dropped / blocked emails don't go unnoticed.
* APM monitoring set up (e.g. Skylight), so that webmaster can diagnose traffic patterns & performance problems when needed
* Error reporting set up (e.g. Rollbar); webmaster is alerted on any server errors
* Test suite covers all business-critical behavior
* Load-testing harness that makes it easy to assess how the current deployment will stand up to various amounts of traffic
* The readme contains:
  - Instructions on local development setup & testing
  - Instructions on how to do load testing
  - Instructions on how to stand up a new app instance
  - Instructions on how to safely deploy changes (incl. db migrations)
  - Instructions on how to scale up or scale down servers to accommodate traffic
  - A link to this production-readiness checklist
