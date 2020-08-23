# How to enable sourcemaps in a Phoenix/Webpack app (WIP)

This is a heavily WIP list of changes I tried to get sourcemaps working reliably on a Phoenix/Webpack app.

---

To make sourcemap testing easier, you can simulate asset compilation locally by running:

    $ rm -rf priv/static/
    $ npm run deploy --prefix assets/
    $ mix phx.digest
    (output will appear in priv/static/)

The Chrome/FF JS inspector should clearly indicate if sourcemaps are available. But I forget exactly what it looks like.

In webpack.config.js, enable sourcemaps in UglifyJsPlugin:

    new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: true }),

Install npm package `source-map-loader`

In webpack.config.js, under rules, add a rule for source-map-loader:


    {
      test: /\.js$/,
      use: ["source-map-loader"],
      enforce: "pre"
    },

In webpack.config.js, under module.exports config, set `devtool: "source-map",`

In Rollbar's JS integration snippet (which configures Rollbar to catch & report JS errors), add option: `source_map_enabled: true,`

In `phoenix_static_buildpack.config`, set `clean_cache=true` to force Heroku to fully rebuild your app on each deploy rather than caching as much as possible. (I suspected that Heroku's cached assets were stale and that was contributing to the failure of sourcemaps. I now think that was not the problem. At any rate, it's easiest if you can test sourcemaps locally.
