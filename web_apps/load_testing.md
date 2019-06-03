## Orienting numbers & concepts

Important concepts:

  * **RPS**: server requests per second. In my benchmarks, RTL (Hobby dyno) can handle 30-45 RPS. Keep in mind that load testing scripts are an artificial environment and don't account for added sources of load like serving assets.
  * **Think time**: how long users look at a screen between actual server requests. 10s is a reasonable starting assumption.
  * **Concurrent users**: The # of users actively doing stuff on the site. Concurrent users = RPS x avg think time (s). RPS = concurrent users / think time (s). Assuming a think time of 10s, RTL's 30-45 RPS will support 300-450 concurrent users.
  * **Peak traffic**: To be safe, assume that this will be ~ 10x average traffic. So if RTL can handle up to 45rps, I should be alarmed if I see the average grow above 5rps.

Some orienting benchmarks on RPS:

  * Per Scout APM's pricing benchmarks, a "small" app serves up to 2 rps (167k requests / day). A "large" app serves up to 8 rps.

  * Per Datadog as of 2019-04, GlassFrog serves avg 3 rps (240k requests / day).
    * Keep in mind the actual rps can be ~ 10x+ during traffic spikes.
    * This number might make GF's popularity appear inflated due to our heavy use of GUPS which could trigger 50+ ajax requests for a single page request. (Migrating to Relay will mostly fix this.)

  * 70 rps (6m requests / day) is considered a large amount of traffic for most sites. For reference, AppSignal APM would cost €500/month for that volume, and Scout APM's largest plan only supports up to 8 rps.


## Writing a load testing script

  * I'm using `k6` for load testing. See https://docs.k6.io/docs/welcome and my proof-of-concept script: sample_k6_load_testing_script.js
  * Identify a common workflow / pathway that users will follow. Write the script to follow this pathway, touching on each page request made in the process.

Keep in mind, k6 has some helpful default behavior:

  * When k6 receives a 3** redirect, it will follow it unless you explicitly disable it.
  * Each VU remembers and re-sends its cookie data (incl. encrypted session) so you don't have to worry about manually providing this with each page request.


## Running the script

Run the same script for a fixed duration, increasing the number of VUs each time, e.g.:

  * `k6 run rtl_admin_1.js --vus=1 --duration=60s`
  * `k6 run rtl_admin_1.js --vus=10 --duration=60s`
  * `k6 run rtl_admin_1.js --vus=20 --duration=60s`
  * `k6 run rtl_admin_1.js --vus=50 --duration=60s`
  * `k6 run rtl_admin_1.js --vus=100 --duration=60s`


## Analyzing the results

Compare results across the different # of VUs:

  * **Avg request duration**: How does this change as # VUs grows? At what point does it become intolerable?
  * **RPS**: How does this change as # VUs grows? At what point do more VUs result in lower RPS?
  * What pages / endpoints are taking the longest? Are there outliers that should be studied separately?
  * At what # of VUs do you start to see hard failures? (eg. response checks fail)

Also check your Heroku / APM stats after doing load testing. Does memory usage grow as the # of virtual users grows? At what point do you start to hit memory constraints? How do response times change? RPS? (note: RPS should grow proportionately but won't be accurate, since the load tests are running in between periods of relative downtime)

Keep in mind, # VUs is not the same as "concurrent users". The virtual users in your load testing script likely have zero "think time".


## Connecting to the real world

  * How many concurrent users do you have / need to have / anticipate having? (keep in mind that this is a tiny fraction of your "active user base")
  * How many RPS would this require?
  * Is this server serving assets in addition to html? If so, keep in mind that the actual viable RPS might be lower than what your load testing script sees.
