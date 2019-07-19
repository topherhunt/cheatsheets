import React from "react"
import PropTypes from "prop-types"

class RedditBrowser extends React.Component {
  componentDidMount() {
    this.props.refreshSubreddit(this.props.selectedId)
  }

  render() {
    return <div>
      <div>
        Available subreddits:

        {this.renderSubredditLink("funny")}
        {this.renderSubredditLink("politics")}
        {this.renderSubredditLink("reactjs")}
        {this.renderSubredditLink("gaming")}
        {this.renderSubredditLink("movies")}
        {this.renderSubredditLink("science")}
        {this.renderSubredditLink("vive")}
      </div>

      <div style={{borderTop: "1px solid #ddd", paddingTop: "1em", marginTop: "1em"}}>
        {this.renderThisSubreddit()}
      </div>
    </div>
  }

  renderSubredditLink(id) {
    return <a href="#"
      style={{
        margin: "0 5px 0 5px",
        fontWeight: (id == this.props.selectedId ? "bold" : "normal")
      }}
      onClick={(e) => {
        e.preventDefault()
        this.props.selectSubreddit(id)
      }}
    >{id}</a>
  }

  renderThisSubreddit() {
    let id = this.props.selectedId
    let subreddit = this.props.dataBySubreddit[id]

    return <div>
      <div style={{fontSize: "130%"}}>{id}</div>
      {this.renderRefreshLink(id, subreddit)}
      {this.renderPostsList(subreddit)}
    </div>
  }

  renderRefreshLink(id, subreddit) {
    if (!subreddit) return "Loading..."

    switch (subreddit.status) {
      case "loading":
        return "Loading..."
      case "loaded":
      case "failure":
        return <a href="#"
          onClick={(e) => {
            e.preventDefault()
            this.props.refreshSubreddit(id)
          }}
        >refresh</a>
    }
  }

  renderPostsList(subreddit) {
    if (!subreddit) return ""

    switch (subreddit.status) {
      case "loading":
        return <div>...</div>
      case "loaded":
        return <div>
          <div>Last updated: {subreddit.lastUpdated}</div>
          {subreddit.posts.map((post) => this.renderPost(post))}
        </div>
      case "failure":
        return <div style={{color: "red"}}>Error loading posts. Try refreshing.</div>
    }
  }

  renderPost(post) {
    return <div key={post.id}
      style={{border: "1px solid #eee", borderRadius: "5px", margin: "5px 0", padding: "5px"}}
    >
      <div style={{fontSize: "110%", fontWeight: "bold"}}>
        <a href={"https://www.reddit.com" + post.permalink} target="_blank">
          {post.title}
        </a>
      </div>
      Posted by {post.author_fullname}. {post.num_comments} comments.
    </div>
  }
}

RedditBrowser.propTypes = {
  selectedId: PropTypes.string.isRequired,
  dataBySubreddit: PropTypes.object.isRequired,
  selectSubreddit: PropTypes.func.isRequired,
  refreshSubreddit: PropTypes.func.isRequired
}

export default RedditBrowser
