# React

## Vue.js

Prefer Vue.js over React:

  * Simpler codebase
  * Easier learning curve
  * Simpler mental model of change propagation
  * Simpler pipeline (doesn't require ES6, JSX, etc.)
  * Templates are more designer-friendly than JSX


## `.setState()`

  * Don't call `.setState({new_state_object})` when the new state is computed from the old state. If you need to reference the old state, instead pass a function, e.g:
  `.setState((prevState) => { return {counter: prevState.counter + 1} })`


## Forms

Article on how to write compact, efficient forms in React: https://medium.com/@everdimension/how-to-handle-forms-with-just-react-ac066c48bd4f
