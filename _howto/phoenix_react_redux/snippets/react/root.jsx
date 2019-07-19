import React from "react"
import PropTypes from "prop-types"
import { Provider } from "react-redux"
import store from "../redux/store"
import RedditBrowserContainer from "./reddit_browser_container.jsx"

class Root extends React.Component {
  render() {
    return <Provider store={store}>
      <h3>Explore Reddit posts</h3>
      <RedditBrowserContainer />
    </Provider>
  }
}

export default Root
