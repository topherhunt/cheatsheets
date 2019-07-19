# How to add Elm to a Phoenix app (or similar)

See also:

  * https://cultivatehq.com/posts/phoenix-elm-2/
  * https://elm-lang.org/0.19.0/init
  * See my dummy Elm app for sample config (in case I missed a step below).


## Steps

  * `cd assets`

  * `npm i --save elm-webpack-loader`

  * Update `webpack.config.js` to add a rule for .elm files:

    ```
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: 'elm-webpack-loader',
          options: {
            cwd: "./elm",
            verbose: true,
            debug: true
          }
        }
      }
    ```

  * In `assets/js/app.js`, link to the Elm init file: `import "../elm/init"`

  * `mkdir elm` (under `assets/`)

  * `cd elm`

  * `elm init` (and say yes.)
    This auto-installs common packages: core, browser, html.

  * Write `assets/elm/init.js`:

    ```
    import SeatSaver from "./SeatSaver.elm"

    let div = document.querySelector("#elm-main")
    if (div) {
      // For more init options, see see Browser.element and Browser.sandbox
      const mainApp = SeatSaver.Elm.SeatSaver.init({node: div})
    }
    ```

  * Create `SeatSaver.elm`:

    ```
    module SeatSaver exposing (..)
    import Html
    main =
      Html.text "Hello from Elm"
    ```

  * In `index.html.eex`, add a target node: `<div id="elm-main"></div>`

  * Now start the server and load the page, and you should see your Elm component render!
