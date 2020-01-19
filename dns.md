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


## CNAME and ALIAS/ANAME

  * A CNAME record cannot coexist with any other records (on the same subdomain). If a CNAME exists, that MUST be the only record on that subdomain.

  * More detail: https://blog.dnsimple.com/2014/01/why-alias-record/


## Heroku site DNS

  * Use whatever domain registrar is cheapest (e.g. Godaddy) but point to Cloudflare nameservers. That way I can use Cloudflare's far better DNS config options.
