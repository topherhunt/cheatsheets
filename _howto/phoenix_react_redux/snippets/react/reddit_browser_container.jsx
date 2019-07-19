import { connect } from "react-redux"
import { SUBREDDIT_SELECTED, SUBREDDIT_REFRESH_REQUESTED } from "../redux/action_creators"
import RedditBrowser from "./reddit_browser.jsx"

// Define what state to provide to the child's props
const mapStateToProps = (state) => ({
  selectedId: state.selectedId,
  dataBySubreddit: state.dataBySubreddit
})

// Define what dispatch callbacks to provide to the child's props
const mapDispatchToProps = (dispatch) => ({
  selectSubreddit: (id) => dispatch(SUBREDDIT_SELECTED(id)),
  refreshSubreddit: (id) => dispatch(SUBREDDIT_REFRESH_REQUESTED(id))
})

// See https://redux.js.org/basics/usage-with-react
const RedditBrowserContainer = connect(mapStateToProps, mapDispatchToProps)(RedditBrowser)

export default RedditBrowserContainer
