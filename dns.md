## Example DNS setup for Mailgun on a subdomain

Here's the setup used on integralclimate.com:

```
CNAME email.mail => mailgun.org.
CNAME www => www.integralclimate.com.herokudns.com.
TXT mail => v=spf1 include:mailgun.org ~all
TXT smtp._domainkey.mail => k=rsa; p=MIGf...
MX @ => mxa.mailgun.org.
MX @ => mxb.mailgun.org.
```
