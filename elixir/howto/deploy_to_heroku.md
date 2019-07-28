# Deploy a Phoenix app to Heroku

Follow these steps to spin up a new Heroku site. If you have multiple Heroku envs for this project, you'll need to add the `-a myapp` flag to each `heroku` command below.

See also: https://hexdocs.pm/phoenix/heroku.html#content


## The steps

  * Create the Heroku app:

    ```
    heroku create myapp
    ```

  * Add the Elixir & Phoenix buildpacks:

    ```
    heroku buildpacks:add https://github.com/HashNuke/heroku-buildpack-elixir.git
    heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
    ```

  * Configure the buildpacks by adding and committing these 3 files in your project root.

    - `elixir_buildpack.config`:

      ```
      # See also: https://github.com/HashNuke/heroku-buildpack-elixir

      erlang_version=20.1
      elixir_version=1.8.1
      ```

    - `phoenix_static_buildpack.config`:

      ```
      # See also: https://github.com/gjaldon/heroku-buildpack-phoenix-static#configuration

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
    heroku addons:create heroku-postgresql:hobby-dev
    heroku addons:create papertrail:choklad
    heroku addons:create rollbar:free
    ```

  * If you need direct S3 upload, see also the S3-related steps in RTL's readme.

  * Set the env vars, referencing `secrets.exs` to see which ones are needed:

    ```
    heroku config:set KEY=value KEY2=value2
    ```

  * Configure Auth0 to allow callbacks on the Heroku domain (eg. myapp.herokuapp.com) rather than just localhost.

  * Deploy the app:
    (the first deploy will take several mins)

    ```
    git push heroku master
    ```

  * Remember to set up the database:

    ```
    heroku run mix ecto.migrate
    ```

  * Test it out!
