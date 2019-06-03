////
// Load testing script for RTL.
//
// Run the script once (eg. for debugging):
// $> k6 run rtl_admin_1.js
//
// Run it with a fixed duration but increasing #s of virtual users:
// $> k6 run rtl_admin_1.js --vus=1 --duration=60s
// $> k6 run rtl_admin_1.js --vus=10 --duration=60s
// $> k6 run rtl_admin_1.js --vus=25 --duration=60s
// $> k6 run rtl_admin_1.js --vus=50 --duration=60s
// $> k6 run rtl_admin_1.js --vus=100 --duration=60s
//

import { check, sleep, group } from "k6"
import http from "k6/http"
import { Trend } from "k6/metrics"

// Gather stats for each individual page load
// (I could get the same data using JSON output and Tags, but this is mentally simpler)
let duration_1 = new Trend("duration_1")
let duration_2 = new Trend("duration_2")
let duration_3 = new Trend("duration_3")
let duration_4 = new Trend("duration_4")
let duration_5 = new Trend("duration_5")
let duration_6 = new Trend("duration_6")
let duration_7 = new Trend("duration_7")

// Phoenix forms have a unique CSRF token that I need to include in the form data.
// I grab it from the prior page's content.
const findCsrfToken = (body) => {
  // console.log("The full body: "+body)
  let regex = /"_csrf_token" type="hidden" value="([^"]+)"/
  let result = regex.exec(body)[1]
  // console.log("Got csrf token: "+result)
  return result
}

const genRandomTag = () => Math.random().toString(36).substring(7)

const submitCodingForm = ({csrfToken, tag}) => {
  let url = "https://rtl-prod.herokuapp.com/manage/projects/demo/videos/1/codings/1"
  let formData = {
    "_csrf_token": csrfToken,
    "_method": "put",
    "_utf8": "✓",
    "coding[tags][124224501][starts_at]": "0:12",
    "coding[tags][124224501][ends_at]": "1:24",
    "coding[tags][124224501][text]": tag}
  let headers = {"Content-Type": "application/x-www-form-urlencoded"}
  let res = http.post(url, formData, headers)
  return res
}

export default function() {
  let res

  // homepage
  res = http.get("https://rtl-prod.herokuapp.com")
  check(res, {"homepage": (r) => r.body.includes("a complex social problem")})
  duration_1.add(res.timings.duration)

  // logging in
  res = http.get("https://rtl-prod.herokuapp.com/auth/force_login/abc123")
  check(res, {"logging in": (r) => r.body.includes("Welcome back, Demo Admin!")})
  duration_2.add(res.timings.duration)

  // projects list
  res = http.get("https://rtl-prod.herokuapp.com/manage/projects")
  check(res, {"proj list": (r) => r.body.includes("test-page-manage-project-list")})
  duration_3.add(res.timings.duration)

  // project dashboard
  res = http.get("https://rtl-prod.herokuapp.com/manage/projects/demo")
  check(res, {"proj dashboard": (r) => r.body.includes("test-page-show-project-1")})
  duration_4.add(res.timings.duration)

  // videos list
  res = http.get("https://rtl-prod.herokuapp.com/manage/projects/demo/videos")
  check(res, {"videos list": (r) => r.body.includes("test-page-manage-video-index")})
  duration_5.add(res.timings.duration)

  // coding page
  res = http.get("https://rtl-prod.herokuapp.com/manage/projects/demo/videos/1/codings/1/edit")
  check(res, {"coding page": (r) => r.body.includes("test-page-code-video-1")})
  duration_6.add(res.timings.duration)

  // update codes
  let csrfToken = findCsrfToken(res.body)
  let tag = genRandomTag()
  res = submitCodingForm({csrfToken: csrfToken, tag: tag})
  check(res, {"update codes": (r) => r.body.includes("test-page-manage-video-index")})
  duration_7.add(res.timings.duration)
}
