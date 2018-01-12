# Heroku

## Basics

- `heroku create`
- `git push heroku master`
- `heroku restart`
- `heroku run rake db:migrate` # arbitrary bash commands can be run this way

## Sync database from Heroku to local

- `heroku pg:backups:capture`
- `heroku pg:backups:download`
- `pg_restore --verbose --clean --no-acl --no-owner -h localhost -U topher -d mydb latest.dump`

## Working with multiple environments

- `heroku create --remote staging` # create a new environment
- `heroku rake db:migrate --app citm-staging`
  # run a Heroku command on a specific environment
  # (required if this app has multiple Heroku environments)

## Troubleshooting

- `heroku ps` - list all running processes on this app
- `heroku ps:stop <process id>` - kill a frozen process
