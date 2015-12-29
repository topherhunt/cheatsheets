# Heroku

## Basics

- `heroku create`
- `git push heroku master`
- `heroku restart`

## Set up ClearDB addon

- `heroku addons:add cleardb:ignite`
- `heroku config | grep CLEARDB`
- `heroku config:set DATABASE_URL='mysql2://username:password@host/database?reconnect=true'`
- Import DB into new environment (that URL contains all the connection credentials)
- `heroku reload`

## Working with multiple environments

- Create a new deploy environment: `heroku create --remote staging`
- Rename an environment: ``
- If a project has multiple environments, specify the app by adding `--app app_name` after the primary command. For example:
  `heroku addons:add --app citm-staging cleardb:ignite`
