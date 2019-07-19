# Redux

References:

  * https://redux.js.org/introduction/getting-started#just-the-basics
  * https://redux.js.org/basics/usage-with-react
  * https://redux.js.org/advanced/async-actions
  * A demo of my latest Redux pattern: https://github.com/topherhunt/redux-pattern-reddit


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

  * The entire app state is stored in a single state object. Think carefully about its shape; try to keep UI state and server-side state clearly separated, and minimize nesting. In particular, consider a tool like Normalizr to flatten JSON API responses into a normalized list of records.


### Reducers

  * Reducers define how your app state will change in response to a given action.
  * For any unknown actions, **the reducer must return the original state**.
  * Reducers MUST be pure and deterministic. They cannot mutate arguments or perform side effects or use non-deterministic inputs (such as Date.now() or Math.random()).
  * In particular, reducers must not mutate the original state. One common pattern to prevent this: `return {...state, newKey: "newValue"}`
  * Consider either using immutable.js, declaring the state as a `const`, or `Object.freeze(state)` to ensure I can't accidentally mutate it.
  * Once your reducers list gets long, break it out into subreducers so it's easier to read and reason about. Each subreducer must know how to handle an empty initial state.
  * I'll name subreducers very explicitly (e.g. `selectedSubredditReducer`).


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

  * Your action creators will be converted into **thunks**: they'll return a function instead of returning the action object directly. This function may have side effects, including making api calls and dispatching other actions.
