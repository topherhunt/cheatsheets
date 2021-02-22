# AWS CLI


## Profiles

Keep in mind that any cli commands you run authorize using a specific _profile_. Find all defined profiles in `~/.aws/credentials`.

When running commands, specify the profile by appending e.g. `--profile h1`. By default the profile `default` is used.


## S3

  * `aws s3 ls` - list buckets
  * `aws s3 ls s3://rtl-prod-eu/` - list contents in a bucket + path
  * `aws s3 mv s3://rtl-prod-eu/uploads/old_filename.jpg s3://rtl-prod-eu/new_filename.jpg`


### Make all objects in an S3 bucket publicly readable

Only do this as a last resort.
Go to the bucket Permissions -> Bucket policy and paste in this policy.
(Make sure to replace the bucket name in the resource line.)

```
{
    "Version": "2012-10-17",
    "Id": "Policy1568277247611",
    "Statement": [
        {
            "Sid": "Stmt1568277235642",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::rtl-prod-eu/*"
        }
    ]
}
```
