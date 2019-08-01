# Redux

References:

  * https://redux.js.org/introduction/getting-started#just-the-basics
  * https://redux.js.org/basics/usage-with-react
  * https://redux.js.org/advanced/async-actions
  * Example Redux pattern #1: https://github.com/topherhunt/redux-pattern-reddit
  * Example Redux pattern #2 (SPA with register/login/logout/profile/reddit browser): [TODO - ref JWT, redux branch]


## Don't use Redux!

Avoid Redux for as long as possible. And if you do adopt it, be very parsimonious with your actions and reducers. Anything that can be kept in local component state / props, should be kept in local component state / props. Redux "flattens out" your app state, imposing a heavy cost in terms of additional layers (and files) you need to traverse in order to reason about a single change.

Consider using [React Context](https://reactjs.org/docs/context.html) before Redux.

Redux is useful if you have a large-scale app and need advanced tools like middleware, time-travel debugging (see React Dev Tools), and logging state progression in production.


## Basic concepts

Concepts: actions, reducers, store, data flow.


### Actions

  * Each Action is an object containing a :type key and any other payload-ish data you need.
  * Define your action types as upcased string constants. That eliminates the risk of typos. Same goes for any other enum strings.
  * Action Creators = functions that create (return) an Action given some input. Note that, unlike vanilla Flux, action creators do NOT dispatch the action, they just return it.
  * Typically define your action types and action creators in `actions.js`.
  * Your reducers MUST be pure & deterministic, but your action creators MAY pull in non-deterministic inputs. (e.g. current time, random uuid...)
  * Try to frame action types in the past tense. It's a thing that happened in the world, that Redux needs to handle. e.g. "NEW_TODO_SUBMITTED".


### State

Think carefully about your state schema. Principles to consider:

  * Have separate top-level keys for :ui (UI-related state), :requests (the status of in-progress or completed api requests), and :data (managed data e.g. records returned from the api).

  * Represent each request's state as an object with a :status string (started, success, failure) plus optional other keys.

  * For data records, consider a tool like Normalizr to flatten JSON API responses into a normalized list of records.


### Reducers

  * Reducers define how your app state will change in response to a given action.

  * Reducers MUST be pure and deterministic. They cannot mutate arguments or perform side effects or use non-deterministic inputs (such as Date.now() or Math.random()). In particular, reducers must not mutate the original state. One common pattern to prevent this: `return {...state, newKey: "newValue"}`

  * For any unknown actions, **the reducer must return the original state**.

  * Once your reducers list gets long, break it out into subreducers so it's easier to read and reason about. Each subreducer must know how to handle an empty initial state.

  * See [my sample Redux token auth setup](https://github.com/topherhunt/phoenix-react-token-auth/blob/redux/assets/js/redux/reducers.js) for an example of how to structure subreducers.

  * When defining subreducers, avoid spread operators and instead define "whole" objects where possible. (It's easier to read & understand the state tree when the code defines whole objects as much as possible.)


### Store

  * The Store is what pulls actions, reducers, and state together and connects them to the outside world: that manages the app state, allows getting state, dispatching actions, and registering & unregistering listeners. Your app will only have one Store, which you create on page init and pass in your main reducer function.

  * Make your store available to the global JS context so that you can run debug commands on it, inspect it etc.


### Data flow

Redux involves strict unidirectional data flow. All data in the app follows the same lifecycle pattern. This makes it extra important to normalize your data (don't have multiple copies of any records etc.)

  1. You call store.dispatch(action) from anywhere in your app.
  2. The store calls the reducer, handing it that action and the current state.
  3. The reducer returns a new state, possibly composed from N sub-reducers. (MUST be deterministic, pure, no side effects)
  4. The new state is announced to any subscribers, and available to anyone who calls `store.getState()`.


## Connecting Redux to React

Concepts: presentation vs. container components, `connect()`, the Provider.

  * Presentational vs. container (data) components. Presentation components shouldn't directly access the Redux store or dispatch actions. If a component is very small, it's OK to combine presentation and Redux logic.
  * Don't write container components by hand; instead use the provided `connect()` function to autogenerate them.
  * Name container components after the thing they contain, plus the word "Container".
  * Design your presentational component hierarchy first, based on the natural breakdown of the UI, then figure out where to squeeze in the container components.
  * To make the Redux store available to all your container components, wrap your root-level component in a Provider, which puts the store in the React tree context.

Define a container component by calling `connect()` and passing it two functions:

  1. mapStateToProps: define what props should be provided to the child of this container. Takes the store's current state as input.
  2. mapDispatchToProps: define callback props that should be provided to the child of this container. This is a function that should return an object where each key is a callback (function) name.

`connect()` returns a function which you immediately call, passing the child (usually a presentation component) that will be rendered inside this container.

  * I think Redux container components can't, or usually don't, take props. It seems expected that all relevant state will be available in the Redux store.


## Patterns

  * I'll avoid the pattern of pre-defining constants for each action type. Instead, `action_creators.js` will export a constant for each action creator, named exactly the same as the action type it returns (or represents, in the case of Thunks). This is a safe approach **as long as there's a test for each action** that verifies that you can generate and dispatch the action and get the correct resulting state.

  * I'll opt to use a separate container component every time I need to access the Redux store, rather than write hybrid components following a completely different pattern. Consistency & learnability over conciseness.

  * Each action dispatched MUST be a reflection of "hey, this thing happened, we have to handle it somehow". Actions cannot be framed as commands, in contrast to the Redux guide's sloppy usage: https://redux.js.org/advanced/example-reddit-api

  * Where possible, each action creator (whether thunk or muggle) should immediately dispatch an action whose type matches the creator name. But there will be some cases where it's better for the dispatched action to have a different name.


## Async actions & AJAX calls

  * A given api request will normally involve dispatching at least 3 actions: 1) an action stating that the request began, 2) an action stating that the request completed, and 3) an action stating that the request failed. A common pattern is to use the same `type` for these 3 actions, and a `status` field to indicate the status of that request.

  * You'll convert some action creators into **thunks**: they'll return a function instead of returning the action object directly. This function may have side effects, including making api calls and dispatching other actions.


## React/Redux development workflow

  - Always start with the desired UI. Then build out the needed React components.
  - Figure out what state they need to reference and what state callbacks they need to call.
  - That will tell you what state Redux needs to store and what actions you'll need to dispatch and what the reducers will do.


## Installing Redux & Thunk

Steps to set up a Phoenix app for Redux state mgmt, with Redux-Thunk for api data syncing.

Given a standard React setup, here's the brief steps for installing Redux.

  * `npm i --save redux redux-thunk redux-logger react-redux`

  * Define the store in `assets/js/redux/store.js`, with middlewares for logger and thunk.

  * Define your action creator functions in `assets/js/redux/action_creators.js`.

  * Define your reducers in `assets/js/redux/reducers.js`.

  * Wrap the React root component in a Redux Provider.



## Possible patterns for Redux state structure

  * The store state has one branch where normalized records are stored: `state.data.records = {users: [incomplete list of records], meals: [...]}`. `records` is an object where each key is the schema/table name and the value is a list of known records of this type. This is an INCOMPLETE list. Any api requests that create, update, or delete record(s) should ensure that all impacted records are added/removed from the records dict. (ie. if a record was deleted, its correspnoding store.data.records entry should be removed.)

  * There's a standard RECORDS_RECEIVED action which you can dispatch and provide the records in the payload. Records can be of any type and can be mixed together; the api must include a "type" field (matching the table name) in each record's json representation so this action's reducer can infer which collection to add/update it to.

  * TODO - whatever I was thinking

  *

  * How to handle paginated collections? I can think of at least 2 approaches:

    - 1: collections aren't stored in Redux. When you page through a collection, you're making a fresh request each time whose response is stored in the local component state. Any records contained in the response are updated in the

    - 2: store partial data on available collections in the store: `state.data.collections` = an object where each key is a collection name (e.g. path without params) and the value is an object {pages: {[pageNum]: [list of ids on this page]}}. This approach lets you cached pages so you can flip back and forth without needing to re-fetch all records on each page flip. But on any record deletion or addition, you need to manually bust the cache for some or all pages.

    ```
    # Example of how this state might be structured
    state: {
      data: {
        records: {...},
        collections: {
          "/users": {
            pages: {
              0: [list of record ids on this page],
              4: [...]
            },
            totalRecords: 193
        }
      }
    }
    ```

  *
