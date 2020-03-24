# GDPR


## Resources

  * https://www.gdprsummary.com/gdpr-summary/
  * https://gdprchecklist.io/
  * https://gdpr.eu/checklist/
  * https://law.stackexchange.com - great Q+A database
  * https://devcenter.heroku.com/articles/gdpr
  * https://github.com/good-lly/gdpr-documents/
  * https://docs.rollbar.com/docs/ruby#section-managing-sensitive-data


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
