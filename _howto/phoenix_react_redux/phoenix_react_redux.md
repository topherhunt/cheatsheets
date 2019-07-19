# Setting up React & Redux in a Phoenix context


## React

  * First, stand up a basic Phoenix app (see `phoenix_new.md`).

  * Follow the steps at https://hexdocs.pm/react_phoenix/readme.html to:
    - Install `react` and `react-dom`
    - Install `@babel/preset-env` and `@babel/preset-react`
    - Add `react_phoenix` to `mix.exs`
    - Add `react_phoenix` to `package.json`
    - Add `react-phoenix` to `app.js`

  * In `webpack.config.js`, modify the .js rule to include .jsx:

    ```js
    test: /\.(js|jsx)$/,
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
      constructor(props) {
        super(props)
        this.state = {}
      }

      render() {
        return <div>Hello from React! Prop: {this.props.ready}</div>
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


## Redux

How to set up a Phoenix app for Redux state mgmt, with Redux-Thunk for api data syncing.

  * First, follow the above steps to set up React.

  * `npm i --save redux react-redux`

  * Install object spread support:
    - `npm i --save-dev @babel/plugin-proposal-object-rest-spread`
    - In `.babelrc`, add this plugin to the **plugins** list
    - (See https://redux.js.org/recipes/using-object-spread-operator for more info)

  * Install `throw` support:
    - `npm i --save-dev @babel/plugin-proposal-throw-expressions`
    - In `.babelrc`, add this plugin to the **plugins** list

  * Add `assets/js/redux/actions.js`. Fill in some starting actions. (see snippet)

  * Add `assets/js/redux/reducers.js`. Fill in some starting reducers. (see snippet)

  * Add `assets/js/redux/store.js`. (see snippet)

  * Import the store in `app.js`.

  * Consider whether your reducers, action creators, or state consumers will need any helper functions for working with & transforming the Redux state. If so, maybe add `assets/js/redux/helpers.js`. (see snippet)

  * Plan out your React component hierarchy as normal, but with an eye towards what Redux connector components you'll need. See snippets for an example connector component and an example presentation component that receives state props and dispatcher props from the connector.

  * Wrap the React root component(s) in a Provider. (see snippet `react/root.jsx`)

[TODO: Update these steps and the snippets with the redux-thunk additions & updated store]
