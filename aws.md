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


### How to set up read/write permissions on a single S3 bucket

When a site needs access to S3, it's best to set up a dedicated IAM role and grant it permission to just the specific bucket(s) needed. There's now a visual permission editor which makes this way easier than it used to be.

  * Create an IAM User (not a role)
  * Enter a name for the user, like `my-app-name`
  * Check "Programmatic access"
  * Under Permissions, click "Attach existing policies", then "Create policy"
  * Create a custom policy with the right access:
    * Select S3
    * Under Actions, check "All actions"
    * Under Resources -> bucket, click "Add ARN" and enter the bucket name. Then check "Any" for the rest of the Resources subsections to clear all warnings.
    * Click "Next", then "Review"
    * Enter a policy name, eg. `s3-my-bucket-full-access`
  * Then go back to the still-in-progress "Add user" tab, refresh the policies list, and check the box next to this new policy
  * Click "Next", then "Review", then "Create"
  * Copy the access key ID & secret to somewhere safe
