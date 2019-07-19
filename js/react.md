# React


## Installing

  * Follow the steps at https://hexdocs.pm/react_phoenix/readme.html.
  * See also `_howto/phoenix_react_redux.md`.


## `.setState()`

  * Don't call `.setState({new_state_object})` when the new state is computed from the old state. If you need to reference the old state, instead pass a function, e.g:
  `.setState((prevState) => { return {counter: prevState.counter + 1} })`


## Forms

Article on how to write compact, efficient forms in React: https://medium.com/@everdimension/how-to-handle-forms-with-just-react-ac066c48bd4f
