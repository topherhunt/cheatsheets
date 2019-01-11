## See also:

K8s local deployment:
https://github.com/holacracyone/glassfrog/wiki/Kubernetes-(k8s):-Getting-started

K8s production deployment:
https://github.com/holacracyone/glassfrog/wiki/Kubernetes-(k8s):-Deploying-to-Production

K8s cheatsheet (editing secrets, etc.):
https://github.com/holacracyone/glassfrog/wiki/Kubernetes-(k8s)-Cheat-Sheet


## Answering questions

What pods & containers are running in this environment?
- `kc use-context eu-development-N`
- `k get pods`

Why aren't containers being created?
- `k describe deployment backend`
- `k get deployment frontend -o yaml`
- `k describe resourcequotas`

Why are containers erroring out?
- Watch Papertrail logs for that environment
- `k logs -f <pod> -c rails`

What code is currently deployed to this environment?
- `k describe deployment frontend | grep Image:`
- Find the GF Git commit id at the end of the image tag.

What cron jobs are applied, and what settings does each one have?
`k get cronjobs`
`k describe cronjob <job-name>`
`k get jobs`

View logs:
`k logs -f <pod> -c rails`


## Changing things

Launch a utility pod:
- `k apply -f k8s/eu/development/utility.yml`

SSH into a pod:
`k exec -it <pod> -c rails -- /bin/bash -l`

Terminate a pod's containers:
(will be recreated based on the deployment settings)
- `k delete pod <pod>`
- `k8s/recycle-pods frontend` (useful in prod where there's tons of pods)

Terminate a deployment (a "service") - won't be auto-recreated until next deploy
Useful if utility deployments are lying around using up resources
`k delete deployment utility`

Copy a file from a pod to local:
`k cp <pod>:~/file/path.csv .`

Get direct psql access:
- `topher.ignore/ssh-utility eu-development-N`
- `psql -h $PGHOST -U postgres`
- `k delete deployment utility` (make sure to clean up afterwards)

Delete all tables from a dev database:
(This is helpful if migrations keep failing)
- `topher.ignore/ssh-utility eu-development-N`
- `psql -U postgres -c '\dt' | grep public | cut -d' ' -f4 | while read table; do psql -U postgres -c "DROP TABLE $table CASCADE;"; done`
- `SELECT 'DROP TABLE "' || tablename || '" CASCADE;' FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;`
- `k8s/update-database` (this will re-populate tables from production)
