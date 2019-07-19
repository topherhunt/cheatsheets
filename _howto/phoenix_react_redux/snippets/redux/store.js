import thunkMiddleware from "redux-thunk"
import { createLogger } from "redux-logger"
import { createStore, applyMiddleware } from "redux"
import { rootReducer } from "./reducers"

const loggerMiddleware = createLogger()

const store = createStore(
  rootReducer,
  applyMiddleware(
    thunkMiddleware, // See https://redux.js.org/advanced/async-actions
    loggerMiddleware // Really nice logging of each action & resulting state
  )
)

export default store

// console.log("Testing that Redux is wired up properly...")
// import * from "./action_creators"

// // Subscribe to store updates (and grab the callback for unsubscribing later)
// let _unsubscribe = store.subscribe(() => console.log("Store state: ", store.getState()))

// store.dispatch(createAction("ADD_TODO", "Learn about actions"))
// store.dispatch(createAction("ADD_TODO", "Learn about reducers"))
// store.dispatch(createAction("ADD_TODO", "Learn about the store"))
// store.dispatch(createAction("SET_VISIBILITY_FILTER", "SHOW_ALL"))
