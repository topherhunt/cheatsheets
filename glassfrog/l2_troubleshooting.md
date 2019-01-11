## DelayedJobs

Running DJ in async mode locally:
(by default, jobs are executed inline)
- In `delayed_job.yml`, set `delay_jobs` = true
- Restart the server
- Run `script/delayed_job run` in a separate tab
- `tail -f log/delayed_job.log`

Removing a failed DJ job so it doesn't retry:
-


## Slack usergroup sync

Relevant logs in Papertrail:
`production (SlackSyncUsergroup OR SlackApiWrapper)`


## Tactical outputs & EmailIntegration notifications

Questions to ask:

- What email address should this alert have gone to?
- Have we sent tactical outputs to that address? (PT logs)
- Have we sent _any_ emails to that address? (PT logs)
- When was the last relevant tactical meeting / object creation event?
