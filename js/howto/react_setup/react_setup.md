# Setting up React in a Phoenix context

Here's my standard setup for a small to medium-size React app. Includes token auth support, ES6 syntax support, and eslint. Excludes Redux.


## React

  * First, stand up a basic Phoenix app (see `phoenix_new.md`).

  * Install `react_phoenix`:
    (see also original steps: https://hexdocs.pm/react_phoenix/readme.html)

    - Add the mix dep: `{:react_phoenix, "~> 1.0"}`
    - `mix deps.get`
    - `cd assets`
    - `npm i --save react react-dom`
    - `npm i --save-dev @babel/preset-react`
    - Add react_phoenix to package.json dependencies list:
      `"react-phoenix": "file:../deps/react_phoenix"`
    - `npm i`
    - In `.babelrc`, add `"@babel/preset-react"` to the **presets** list
    - In `app.js`, add `import "react-phoenix"`

  * In `webpack.config.js`, modify the .js rule to include .jsx:

    ```js
    test: /\.jsx?$/,
    ```

  * In `app.js`, import your React globals file:

    ```js
    import "./react/globals"
    ```

  * Write your React globals file (`assets/js/react/globals.js`):

    ```js
    import Root from "./root.jsx"
    window.Components = {Root}
    ```

  * Write your Root component (`assets/js/react/root.jsx`):

    ```jsx
    import React from "react"
    import PropTypes from "prop-types"

    class Root extends React.Component {
      render() {
        return <div>Hello from React! Readiness status: {this.props.ready}</div>
      }
    }

    Root.propTypes = {
      ready: PropTypes.string.isRequired
    }

    export default Root
    ```

  * In a template, render the root component:

    ```rb
    <%= ReactPhoenix.ClientSide.react_component("Components.Root", %{ready: "Yes sir!"}) %>
    ```

  * Load that page to confirm that the component renders & no JS errors appear.


## ES6 support

Install Babel plugins for better ES6 support:
(See https://redux.js.org/recipes/using-object-spread-operator for more info)

  * `npm i --save-dev @babel/plugin-proposal-object-rest-spread @babel/plugin-proposal-throw-expressions`

  * Add these plugins to `.babelrc`:

    ```js
    "plugins": [
      "@babel/plugin-proposal-object-rest-spread",
      "@babel/plugin-proposal-throw-expressions"
    ]
    ```


## ESLint

Installing ESLint can help protect me from some of JS' footguns.

  * `npm i --save-dev eslint babel-eslint eslint-loader eslint-plugin-react`.
    - `babel-eslint` uses the Babel config to teach eslint how to parse our files
    - `eslint-loader` lets you set up Webpack to run eslint and print any errors
    - `eslint-plugin-react` helps eslint make sense of jsx markup

  * Write the eslint config file, `assets/.eslintrc.js` (see snippet).

  * In `webpack.config.js`, add a new rule ABOVE your existing .js rule:

    ```js
    {
      enforce: "pre", // eslint must run before any babel transpilation stuff
      test: /\.jsx?$/,
      exclude: /(deps|node_modules)/, // Exclude Elixir deps from linter
      loader: "eslint-loader"
    },
    ```

  * Start your server. Confirm that Webpack compiles and correctly warns you of linter errors both in .js and .jsx files. Fix the warnings.


## Jest

TODO: Add steps for installing Jest for react component unit tests.

See also:

  * https://jestjs.io/docs/en/getting-started.html
  * `jest.md`


## Client-side token auth support

Conceptually, token auth in React is very simple. My general approach:

  * The main component has an `authedUser` state to track who is logged in (null if not logged in).

  * The authToken itself is stored in `localStorage` so it persists between refreshes.

  * There's also a `setAuthedUser` function which stores the token in localStorage and sets the authedUser, plus a `logout` function which clears the authed user & token.

  * In the main component, on `componentDidMount`, if an authToken exists in local storage, set the authedUser state accordingly.

  * If your UI will have different "views", consider adding a `currentView` state to the main component and organizing each view component into e.g. `react/views/login_view.jsx` to minimize clutter.

  * Pass `authedUser` as a prop to any children that need to know whether you're logged in. Pass `setAuthedUser` if a child component will need to log you in.

  * Write a LoginView component that displays the login form, manages state of the login request, and calls `setAuthedUser` to store the token & set authedUser on success.

  * Write a RegisterView component that supports first-time signup (flow will be similar to LoginView).

  * All requests to my api are made using a `makeApiRequest` helper which adds the auth token to the header if available, and also does common steps like encoding the JSON body, decoding the JSON response, and checking for 5** errors.

You do NOT need Redux and Thunk to build a non-trivial token-authed SPA. If your component tree is getting too large to simply pass down props, consider setting up a React Context which is much lower-maintenance and easier to reason about than Redux actions & reducers.

See [my `phoenix-react-token-auth` repo](https://github.com/topherhunt/phoenix-react-token-auth) for an example implementation. (relevant code is under `assets/js/react/`)

Testing requests with curl:

```sh
curl -D - /api/users/me -H "Authorization: Bearer <valid_jwt_token>"
```


## Next?

  * Consider whether you'll use React Router: https://redux.js.org/advanced/usage-with-react-router

  * Need to manage lots of api state across diverse components? Consider [React Context](https://reactjs.org/docs/context.html) as a simpler alternative to Redux. Set up a StoreProvider component whose only job is to provide state (and functions to update state) to a context which any descendant component can then be a Consumer of. For an example, see [here](https://daveceddia.com/context-api-vs-redux/) under "Pass actions down through context".
