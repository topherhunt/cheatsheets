# Heroku


## Basics

  - `heroku create my-app-name --region eu`
  - `git push heroku master`
  - `heroku restart`
  - `heroku run rake db:migrate` # arbitrary bash commands can be run this way


## Sync database from Heroku to local

  - `heroku pg:backups:capture -a my_app`
  - `heroku pg:backups:download -a my_app`
  - `pg_restore --verbose --clean --no-acl --no-owner -d my_local_db latest.dump`
    (run it twice to ensure there's no persistent errors)
  - `rm latest.dump`

There's also a shortcut: `heroku pg:pull -a my_app DATABASE_URL my_local_db`


## Sync database from local to Heroku

  - `heroku pg:backups:capture -a my_app`
  - `heroku pg:reset -a my_app --confirm=my_app`
  - `heroku pg:push -a my_app my_local_db DATABASE_URL` (DATABASE_URL is a literal)


## Working with multiple environments

```
# create a new environment:
heroku create --remote staging

run a Heroku command on a specific environment:
heroku rake db:migrate -a mapp-staging
```


## Parsing Papertrail logs

- Download all logfiles as .tsv.gz into a folder
- Run `sh ~/Sites/personal/utilities/combine_pt_logs.sh` to unpack all logs, combine them into one file, and clean up their format
- `less cleaned.tsv`


## Troubleshooting

- `heroku ps` - list all running processes on this app

- `heroku ps:stop <process id>` - kill a frozen process

- `heroku repo:purge_cache -a appname` - clear the build cache.
  Useful if deploy fails due to tmpfile permission errors. More info: https://help.heroku.com/18PI5RSY/how-do-i-clear-the-build-cache

- Check how many cores a dyno has:
  ```
  heroku run /bin/bash
  grep -c processor /proc/cpuinfo
  ```

