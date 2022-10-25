# GDPR


## Resources

  * https://www.gdprsummary.com/gdpr-summary/
  * https://gdprchecklist.io/
  * https://gdpr.eu/checklist/
  * https://law.stackexchange.com - great Q+A database
  * https://devcenter.heroku.com/articles/gdpr
  * https://github.com/good-lly/gdpr-documents/
  * https://docs.rollbar.com/docs/ruby#section-managing-sensitive-data
  * Clear, friendly privacy policy example: https://fly.io/legal/privacy-policy/


## Legal questions

  * Q: Does a data deletion request obligate me to delete DB backups/archives that contain a copy of that customer's data?
    No. The need for DB backups in case of data loss is a legitimate interest of the company, thus the customer's request for data deletion does not necessarily extend to backups. https://law.stackexchange.com/a/37790/28792 However you MUST keep a list of all data deletion requests so that you can re-execute them in the event that you ever restore one of those backups.

  * Q: Is Heroku a GDPR-compatible PaaS?
    - If the company or primary customer base is in the EU, probably NO because of Heroku's lengthy subprocessors list and use of AWS hosting. Instead use an EU-based PaaS such as Scalingo or [others here](https://european-alternatives.eu/category/paas-platform-as-a-service).
    - For a US-based company whose main customer base is not in the EU, Heroku might be OK. [This page](https://fly.io/legal/privacy-policy/) affirms that US-based services don't need to host their servers & data in the EU -- although assuming you have any EU customers, you're still held to the same standards for data protection, privacy, and handling of deletion requests and breaches.
    - {TBD} But US-based companies that have _any_ EU clients still need to execute DPAs with all subprocessors of their data; Heroku's kafkaesque network of subprocessors makes this nearly impossible to comply with.

  * Q: Is Papertrail a GDPR-compatible logging service?
    - If the company or primary customer base is in the EU, probably no because the logs (a) contain personal data and (b) are stored in the US and hosted on AWS which is fraught.
    - For a US-based company whose main customer base is not in the EU, Papertrail is probably OK. Papertrail's 1-year retention isn't a dealbreaker; per [this advice](https://law.stackexchange.com/a/34140/28792), data deletion requests do NOT obligate you to delete your webrequest logs even if they contain personal data, because you have a legitimate interest in retaining those logs in order to ensure network security. But because the logs contain personal data, you DO need to state on your privacy page that you're storing them, for how long, what they contain, and your legal basis for doing so; [see here](https://law.stackexchange.com/a/42448/28792).

  * Q: Do IP addresses count as personal data?
    - Per [this argument](https://law.stackexchange.com/questions/42438/do-default-apache-logs-violate-the-gdpr), YES if the IP can be linked to identifying data of a specific individual. In context of logging non-scrubbed webserver requests, this almost definitely means yes.

  * Q: Do US-based companies whose main customer base is not in the EU, have to prepare data processing agreements with all subprocessors of personal data?
    - I think the default answer is yes, but I need to get more confirmation of this.


## Compliance checklist

  * Create a document `gdpr.md` in the app, for internal notes on the compliance process.

  * The app has a "Privacy policy" and a "Terms & conditions" pages.
    (See WVJ for a generic example of each.)

  * All data is either stored within the EU, or if stored in the US, is stored with a company that has PrivacyShield certification.
    (See https://ec.europa.eu/info/law/law-topic/data-protection/international-dimension-data-protection/adequacy-decisions_en for explanation. https://gdprtracker.io/ can help determine which services are PrivacyShield certified. Papertrail and Rollbar are both PrivacyShield-certified.)

  * If any data is transferred/stored outside of the EU, the privacy policy must mention this and identify the companies processing it.

  * If logging IPs, ensure you declare this in the privacy policy ande xplain the legal basis.
    (IP logging is acceptable even without consent because it's in the interest of security. But you do need to declare it in the privacy policy. See https://law.stackexchange.com/a/28609/28792)

  * If using Google Analytics, follow this advice to ensure I'm compliant: https://law.stackexchange.com/q/28367/28792.
    (Basically, you need to explicitly configure GA for anonymization, then you can avoid the cookie banner and only need to mention a few things in your data policy.)

  * Determine if I need a cookie warning. You don't need to show a cookie banner if your website only uses cookies that are essential to providing the service, eg. storing account info. https://github.blog/2020-12-17-no-cookie-for-you/

  * Complete [this GDPR checklist](https://gdprchecklist.io/). In `gdpr.md`, note any links, decisions, answers to checklist questions, etc.

  * Also review [the official GDPR checklist](https://gdpr.eu/checklist/) and ensure nothing is missing.

  * Prepare a spreadsheet to track GDPR requests, with the following columns:
    - Requester name
    - Requester organization (if any)
    - Requester email / contact info
    - Type (data access, data transfer, stop processing, stop profiling, forget me)
    - Due date
    - Status (new -> in progress -> completed)
    - Assignee

  * Review Rollbar's GDPR advice: https://docs.rollbar.com/docs/ruby#section-managing-sensitive-data - note any other tensions that creates

  * Pretend you just received [this broad GDPR request letter](https://github.com/good-lly/gdpr-documents/blob/master/data-access/en/GDPR%20data%20access.md) and practice handling it, to ensure you've got all the pieces in place.


## Handling data requests

  * Start by confirming their identity. Ask for a scan of a photo id (eg. passport or drivers license). Refuse any requesters who don't prove who they are.
    (This of course means that user data requests can't safely be processed unless I retain enough data to determine whether the requester is in fact the owner of that data.)
