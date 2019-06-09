# Load testing / performance testing


## Orienting concepts & numbers

Important concepts (with some orienting numbers from my hobby app, RTL):

  * **RPS**: server requests per second. [Scout APM](https://scoutapm.com/info/pricing) considers 2 rps (167k req / day) a "small" amount of traffic and 8 rps (690k req / day) a "large" amount.
    * Keep in mind that there's various kinds of requests and they have different performance implications: page loads (which often invoke lots of db queries, then render a complex HTML page), AJAX and API requests (often more lightweight and have less to render), and assets such as images/JS/CSS (which can be much larger in size, but are usually cached by the browser). A single full page load is often accompanied by 10+ asset requests, more if the site isn't well optimized. Also, consider that cached pages are much less expensive to serve than pages that need to be recomputed from scratch. The APM metrics above refer to just page loads / ajax / api requests, and exclude assets.
    * In my tests, RTL can handle 30-60 HTML page requests per second. But if I also request the assets that the browser would normally request (images/JS/CSS), then it can only handle ~ 6 rps. So if you're serious about throughput, the first thing to do is to offload all assets (incl. JS and CSS) to a CDN of some sort.
  * **Think time**: how long users look at a screen between actual server requests. 10s is a reasonable starting assumption.
  * **Concurrent users**: The # of users actively doing stuff on the site. Concurrent users = RPS x avg think time (in secs). RPS = concurrent users / think time. Assuming a think time of 10s, RTL's 30-45 RPS will support 300-450 concurrent users.
  * **Peak traffic**: To be safe, assume that website traffic will routinely spike to ~ 10x the average. So if RTL can safely handle up to 45rps, I should be alarmed if I see the average grow above 5rps.


## Writing a load testing script

  * I'm using `k6` for load testing. See https://docs.k6.io/docs/welcome and my proof-of-concept script: `sample_k6_load_testing_script.js`
  * Identify a common workflow / pathway that users will follow. Write the script to follow this pathway, touching on each page request made in the process.
  * If your server will also serve assets, it's important to include those in the test. Note all requests that your browser makes (most assets will be cached across page requests) and mimic them. This will make your results much more realistic.

K6 has some helpful behavior that makes your life easier:

  * When k6 receives a 3** redirect, it will follow it unless you explicitly disable it.
  * Each VU remembers and re-sends its cookie data (eg. encrypted session) so you don't have to worry about manually providing this with each page request.


## Running the script

Run the same script for a fixed duration, increasing the number of VUs each time, e.g.:

  * `k6 run k6_script.js --vus=1 --duration=60s`
  * `k6 run k6_script.js --vus=10 --duration=60s`
  * `k6 run k6_script.js --vus=20 --duration=60s`
  * `k6 run k6_script.js --vus=50 --duration=60s`
  * `k6 run k6_script.js --vus=100 --duration=60s`

If you have trouble running k6 locally, they also have a Docker image:

  * `docker pull loadimpact/k6`
  * `docker run -i loadimpact/k6 run --vus=50 --duration=60s -< k6_script.js`


## Running load tests from an Amazon EC2 instance

If you have a solid internet connection, you can run the load testing script from your local machine and expect insightful results. But the bandwidth & delay between your computer and the server will always be an intervening variable; for purest results, run the script on a cloud vps. Here's how to run it on an EC2 instance:

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

Compare results across the different # of Virtual Users:

  * **Avg request duration**: How does this change as # VUs grows? At what point does it become intolerable?
  * **RPS**: How does this change as # VUs grows? At what point do more VUs result in lower RPS?
  * What pages / endpoints are taking the longest? Are there outliers that should be studied separately?
  * At what # of VUs do you start to see hard failures? (eg. response checks fail)

Also check your Heroku / APM stats after doing load testing. Does memory usage grow as the # of virtual users grows? At what point do you start to hit memory constraints? How do response times change? RPS? (note: RPS should grow proportionately but won't be accurate, since the load tests are running in between periods of relative downtime)

Keep in mind, # VUs is not the same as "concurrent users". The virtual users in your load testing script likely have zero "think time", meaning they make another request as soon as the previous request is served, whereas real users will often taken 10+ seconds to do stuff on a page before making another request.


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
