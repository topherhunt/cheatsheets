# Load testing / performance testing


## Orienting concepts & numbers

Important concepts:

  * **RPS**: server requests per second. In my benchmarks, RTL (Hobby dyno) can handle 30-45 RPS. Keep in mind that load testing scripts are an artificial environment and don't account for added sources of load like serving assets.
  * **Think time**: how long users look at a screen between actual server requests. 10s is a reasonable starting assumption.
  * **Concurrent users**: The # of users actively doing stuff on the site. Concurrent users = RPS x avg think time (in secs). RPS = concurrent users / think time. Assuming a think time of 10s, RTL's 30-45 RPS will support 300-450 concurrent users.
  * **Peak traffic**: To be safe, assume that website traffic will routinely spike to ~ 10x the average. So if RTL can safely handle up to 45rps, I should be alarmed if I see the average grow above 5rps.

Some orienting RPS numbers:

  * Per Scout APM's pricing benchmarks, a "small" app serves up to 2 rps (167k requests / day). A "large" app serves up to 8 rps.

  * 70 rps (6m requests / day) is considered a large amount of traffic for most sites. For reference, AppSignal APM would cost €500/month for that volume, and Scout APM's largest plan only supports up to 8 rps.


## Writing a load testing script

  * I'm using `k6` for load testing. See https://docs.k6.io/docs/welcome and my proof-of-concept script: `sample_k6_load_testing_script.js`
  * Identify a common workflow / pathway that users will follow. Write the script to follow this pathway, touching on each page request made in the process.

Keep in mind, k6 has some helpful default behavior:

  * When k6 receives a 3** redirect, it will follow it unless you explicitly disable it.
  * Each VU remembers and re-sends its cookie data (incl. encrypted session) so you don't have to worry about manually providing this with each page request.


## Running the script

Run the same script for a fixed duration, increasing the number of VUs each time, e.g.:

  * `k6 run k6_script.js --vus=1 --duration=60s`
  * `k6 run k6_script.js --vus=10 --duration=60s`
  * `k6 run k6_script.js --vus=20 --duration=60s`
  * `k6 run k6_script.js --vus=50 --duration=60s`
  * `k6 run k6_script.js --vus=100 --duration=60s`


## Running load tests from an Amazon EC2 instance

If you do load testing from your local machine, the bandwidth between your computer and the server might interfere with the accuracy of the test and give you poorer results than what your server can actually . Run your load tests on an EC2 instance to eliminate this variable.

  * Spin up an EC2 instance with 8GB+ of memory. I'm using Amazon Linux AMI.
  * SSH in: `ssh YOUR_EC2_INSTANCE_ADDRESS -i ~/.ssh/YOUR_KEYPAIR_FILE`
  * `sudo yum update -y`
  * `sudo amazon-linux-extras install docker`
  * `sudo service docker start`
  * `sudo usermod -a -G docker ec2-user`
  * Exit and reconnect (to start a new session)
  * `docker run hello-world` (test that Docker is set up properly)
  * Use `nano` to write the script you want to run to `k6_script.js`
  * `docker pull loadimpact/k6`
  * `docker run -i loadimpact/k6 run --vus=50 --duration=60s -< k6_script.js`

## Analyzing the results

Compare results across the different # of VUs:

  * **Avg request duration**: How does this change as # VUs grows? At what point does it become intolerable?
  * **RPS**: How does this change as # VUs grows? At what point do more VUs result in lower RPS?
  * What pages / endpoints are taking the longest? Are there outliers that should be studied separately?
  * At what # of VUs do you start to see hard failures? (eg. response checks fail)

Also check your Heroku / APM stats after doing load testing. Does memory usage grow as the # of virtual users grows? At what point do you start to hit memory constraints? How do response times change? RPS? (note: RPS should grow proportionately but won't be accurate, since the load tests are running in between periods of relative downtime)

Keep in mind, # VUs is not the same as "concurrent users". The virtual users in your load testing script likely have zero "think time".


## Example: Load testing RTL

RTL is a small Phoenix web app running on a Heroku hobby dyno. I wrote a load testing script that loads the homepage, logs in as admin, navigates into a project, and updates tags on a video. The script makes 10 page requests per iteration. I run it for 60s each time, with increasing numbers of virtual users: 1, 10, 25, 50, 100, 250, 500.

Results & notes:

  * RPS is highest at 50 VUs, varying between 50 and 150(!!) rps with no errors. Average request duration grows steadily with the # of VUs; at 100 VUs the request duration reaches 1s-1.3s, which is my max acceptable request time. You start to see timeouts & errors at 200+ VUs (when run from EC2; or 400+ VUs when run from my local machine, due to bandwidth constraints).

  * Interestingly, the slowest request is loading the video coding page. At 100 VUs, loading this page takes avg 7.6 seconds. The second slowest request is _updating_ the codes for a video, which takes 25-50% as long on average.

  * RTL is currently running a single Phoenix server on a single Heroku Hobby dyno ($7/mo) with a pool of 10 database connections. I'm guessing this db pool is the main limiting factor right now. Upgrading to a Standard 2X dyno ($50/mo) only marginally increases throughput (~ +30%).

  * The Hobby dyno has a memory quota of 512 MB; testing with 100 VUs causes memory usage to jump to ~ 750 MB, so if I anticipate spikes of 100 concurrent requests (aka ~ 1000 concurrent users), I should upgrade to a dyno with at least 1 GB of memory.

  * Assuming an avg think time of 10s per page, tolerable performance at 100 VUs means RTL can comfortably handle 1000 concurrent users. But this doesn't account for assets (images, JS, CSS) which the server must also serve, but the load testing script doesn't request.


## Connecting to the real world

  * How many concurrent users do you have / need to have / anticipate having? (keep in mind that this is a tiny fraction of your "active user base")
  * How many RPS would this require?
  * Is this server serving assets in addition to html? If so, keep in mind that the actual viable RPS might be lower than what your load testing script sees.
