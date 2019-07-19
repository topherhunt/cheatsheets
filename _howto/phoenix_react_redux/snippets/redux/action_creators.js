// Gratuitous pass-through function for readability
const Thunk = (theFunction) => theFunction

//
// Action creator functions
//

export const SUBREDDIT_SELECTED = (subredditId) => {
  return Thunk((dispatch, getState) => {
    dispatch({type: "SUBREDDIT_SELECTED", subredditId})

    let subreddit = getState().dataBySubreddit[subredditId]
    if (!subreddit || !subreddit.posts) {
      helpers.fetchPostsThenUpdateState(dispatch, subredditId)
    }
  })
}

export const SUBREDDIT_REFRESH_REQUESTED = (subredditId) => {
  return Thunk((dispatch) => {
    helpers.fetchPostsThenUpdateState(dispatch, subredditId)
  })
}

export const FETCH_POSTS_STARTED = (subredditId) => {
  return {type: "FETCH_POSTS_STARTED", subredditId}
}

export const FETCH_POSTS_SUCCESS = (subredditId, json) => {
  return {
    type: "FETCH_POSTS_SUCCESS",
    subredditId: subredditId,
    posts: json.data.children.map((child) => child.data),
    receivedAt: Date.now()
  }
}

export const FETCH_POSTS_FAILURE = (subredditId) => {
  return {type: "FETCH_POSTS_FAILURE", subredditId}
}

//
// Private helpers for fetching data etc.
//

let helpers = {
  fetchPostsThenUpdateState: (dispatch, subredditId) => {
    dispatch(FETCH_POSTS_STARTED(subredditId))
    fetch(`https://www.reddit.com/r/${subredditId}.json`)
      .then((response) => {
        if (!response.ok) throw(`Got bad response code: ${response.status}`)
        return response.json()
      })
      .then((json) => {
        if (true) {
          dispatch(FETCH_POSTS_SUCCESS(subredditId, json))
        } else {
          dispatch(FETCH_POSTS_FAILURE(subredditId))
        }
      })
      .catch((error) => {
        dispatch(FETCH_POSTS_FAILURE(subredditId))
      })
  }
}
