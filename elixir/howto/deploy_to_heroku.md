# Deploy a Phoenix app to Heroku

Follow these steps to spin up a new Heroku site. If you have multiple Heroku envs for this project, you'll need to add the `-a myapp` flag to each `heroku` command below.

See also: https://hexdocs.pm/phoenix/heroku.html#content


## The steps

  * Create the Heroku app and add the standard buildpacks:

    ```
    heroku create myapp
    heroku buildpacks:add https://github.com/HashNuke/heroku-buildpack-elixir.git
    heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
    ```

  * Configure the buildpacks by adding and committing these 3 files in your project root:

    - `elixir_buildpack.config`:

      ```
      # See https://github.com/HashNuke/heroku-buildpack-elixir

      erlang_version=20.1
      elixir_version=1.8.1
      ```

    - `phoenix_static_buildpack.config`:

      ```
      # See https://github.com/gjaldon/heroku-buildpack-phoenix-static#configuration

      clean_cache=false
      compile="buildpack_compile_script"
      phoenix_ex=phx

      # (specify Node version to make Webpack happy)
      node_version=8.9.3
      npm_version=6.10.2
      ```

    - `buildpack_compile_script`:

      ```
      # See https://hexdocs.pm/phoenix/heroku.html#adding-the-phoenix-static-buildpack

      npm run deploy
      cd $phoenix_dir
      mix "${phoenix_ex}.digest"
      ```

  * Then commit these config files to git.

  * Add my commonly-needed addons:

    ```
    heroku addons:create heroku-postgresql:hobby-dev # (or hobby-basic for $9/mo)
    heroku addons:create papertrail:choklad
    heroku addons:create rollbar:free
    ```

  * Set it up at a subdomain if desired:
    - In the Heroku app settings dashboard, add the desired domain. Copy the target domain that Heroku provides.
    - In the DNS admin panel (eg. Cloudfront or Namecheap), add a CNAME pointing to the target provided by Heroku.

  * If you need direct S3 upload, see also the S3-related steps in RTL's readme.

  * Set the env vars, referencing `secrets.exs` to see which ones are needed:

    ```
    heroku config:set KEY=value KEY2=value2
    ```

  * Deploy the app: `git push heroku master` (the first deploy will take several mins)

  * Set up the database: `heroku run mix ecto.migrate`

  * Smoke test to ensure everything is wired up properly:

    - Site is reachable
    - Backend errors are reported to Rollbar
    - Frontend errors are reported to Rollbar
    - Request logs are visible in Papertrail
    - Emails are sent as expected
