# CORS


Resources:

  - https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#The_HTTP_response_headers
  - https://www.test-cors.org/ (mildly useful)


On Elixir, set up CORS headers using `cors_plug`. Set access-control-allowed-origin thusly, instead of leaving the default `*` (which is rejected when the ajax request includes credentials):

```
plug CORSPlug, origin: [
  ~r/https?\:\/\/(.+\.)*spartan\.com$/,
  ~r/test-cors\.org/,
  ~r/https?\:\/\/localhost/
]
```
