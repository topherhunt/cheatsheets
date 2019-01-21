## DelayedJobs

Running DJ in async mode locally:
(by default, jobs are executed inline)
- In `delayed_job.yml`, set `delay_jobs` = true
- Restart the server
- Run `script/delayed_job run` in a separate tab
- `tail -f log/delayed_job.log`

Removing a failed DJ job so it doesn't retry:
-


## Habit support

To reset a person to the 1st HS lesson: See `HabitSupportRecipient#skip_to_lesson!`, there's useful comments there


## Proposals & governance meetings

The old proposal builder would often timeout while trying to accept proposals w large side-effects e.g. circle deletions. You can bypass this by accepting from the console:

- Craft the proposal in a real meeting
- Open the JS console, find the GOV_MTG_PROPOSAL_UPDATE statement, get the proposalId and meetingId
- In the console:
  ```
  p = Proposal.find(proposalId)
  p.update!(meeting_id: meetingId)
  p.accept_in_meeting!
  ```
- Refresh the meeting page and you should see that the proposal is accepted and its change has been applied.


## Slack usergroup sync

Relevant logs in Papertrail:
`production (SlackSyncUsergroup OR SlackApiWrapper)`


## Tactical outputs & EmailIntegration notifications

Questions to ask:

- What email address should this alert have gone to?
- Have we sent tactical outputs to that address? (PT logs)
- Have we sent _any_ emails to that address? (PT logs)
- When was the last relevant tactical meeting / object creation event?
