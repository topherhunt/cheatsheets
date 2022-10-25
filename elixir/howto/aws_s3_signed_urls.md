# How to generate a signed URL for accessing a private file on S3

See also:

* [Direct file upload from browser to S3](https://stackoverflow.com/a/42211543/1729692)

---

In `config.exs`:

```rb
config :ex_aws,
  access_key_id: H.env!("S3_ACCESS_KEY_ID"),
  secret_access_key: H.env!("S3_SECRET_ACCESS_KEY"),
  region: H.env!("S3_REGION"),
  s3: [
    scheme: "https://",
    host: H.env!("S3_HOST"),
    region: H.env!("S3_REGION")
  ]
```

In your controller or helper:

```rb
config = ExAws.Config.new(:s3)
bucket = H.env!("S3_BUCKET")
path = "path/to/the/file.jpg"
{:ok, url} = ExAws.S3.presigned_url(config, :get, bucket, path, virtual_host: true)
url
```
