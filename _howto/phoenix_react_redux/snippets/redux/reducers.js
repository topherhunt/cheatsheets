const rootReducer = (state = {}, action) => {
  return {
    selectedId: selectedIdReducer(state.selectedId, action),
    dataBySubreddit: dataBySubredditReducer(state.dataBySubreddit, action)
  }
}

const selectedIdReducer = (subredditId = "reactjs", action) => {
  switch (action.type) {
    case "SUBREDDIT_SELECTED":
      return action.subredditId
    default:
      return subredditId
  }
}

const dataBySubredditReducer = (dataBySubreddit = {}, action) => {
  if (!!action.subredditId) {
    // If the action has a subredditId, let's run the reducer for that subreddit.
    let subreddit = dataBySubreddit[action.subredditId]
    subreddit = subredditReducer(subreddit, action)
    return {...dataBySubreddit, [action.subredditId]: subreddit}
  } else {
    return dataBySubreddit
  }
}

const subredditReducer = (subreddit, action) => {
  switch (action.type) {
    case "FETCH_POSTS_STARTED":
      return {...subreddit, status: "loading"}
    case "FETCH_POSTS_SUCCESS":
      return {
        ...subreddit,
        status: "loaded",
        posts: action.posts,
        lastUpdated: action.receivedAt
      }
    case "FETCH_POSTS_FAILURE":
      return {...subreddit, posts: null, status: "failure"}
    default:
      return subreddit
  }
}

export { rootReducer }
