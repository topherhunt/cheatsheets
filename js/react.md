# React


## Primer & basics

- [Intro tutorial](https://reactjs.org/tutorial/tutorial.html) - great refresher.

- A _stateless component_ just needs the [class definition](https://reactjs.org/docs/components-and-props.html) and a `render()` function. Simple pure components can also be [written as a function](https://reactjs.org/docs/components-and-props.html) with one `props` argument.

- A <u>stateful</u> component uses the class structure, + needs a `constructor` which sets the starting state based on the props.


## Gotchas

- [Common mistakes when writing a constructor](https://www.digitalocean.com/community/tutorials/react-constructors-with-react-components)

- When you use `setState()`, don't reference the prior state directly. Instead use setState's function form. [details](https://reactjs.org/docs/faq-state.html#why-is-setstate-giving-me-the-wrong-value)

- When rendering items in a loop, each item must have a [unique key](https://reactjs.org/docs/lists-and-keys.html). React will warn you if you forget to do this.

- Advice on [how to plan, architect, mockup, and build](https://reactjs.org/docs/thinking-in-react.html) your React UI.

- React's docs don't endorse any particular api/datasyncing framework, instead they say to start by [making plain Jquery/Axios/window.fetch calls](https://reactjs.org/docs/faq-ajax.html) in `componentDidMount()`.

- [React Router](https://github.com/remix-run/react-router) is the canonical routing system. [advanced guide](https://ui.dev/react-router-tutorial)

- You're encouraged [not to use a state library like Redux](https://redux.js.org/faq/general#when-should-i-use-redux) unless you've fully exhausted React's built-in state & lifecycle tools. React Contexts can do everything Redux does, but often it's too low-level & footgunny; see also the useReducer hook for a lightweight Redux.

- The [`useEffect()`](https://reactjs.org/docs/hooks-effect.html) hook lets you run certain logic (ie. side effects) whenever the component mounts or rerenders. It's like `componentDidMount()` and `componentDidUpdate()`, but it works in function components. NB: Make sure you don't set state in an async callback if the component has become unmounted! [howto](https://www.digitalocean.com/community/tutorials/how-to-call-web-apis-with-the-useeffect-hook-in-react#step-2-fetching-data-from-an-api-with-useeffect)


## Basic app setup checklist

- In Phoenix, follow the steps at https://hexdocs.pm/react_phoenix/readme.html.
- `npx create-react-app tutorial-game`
- `cd tutorial-game`
- `npm start` - starts the dev app and opens it in the browser.


## Fav libraries

- useReducer hook
- [React Query](https://tanstack.com/query/v4/?from=reactQueryV3&original=https://react-query-v3.tanstack.com/), a whole-package api querying & state mgmt library
- Handy troubleshooting tool: [useWhyDidYouUpdate hook](https://usehooks.com/useWhyDidYouUpdate/) helps you ID what prop/var changes caused a (functional) component to re-render.


## Testing

In a Jest test, write the current component HTML out to a file:

```js
const fs = require("fs")
fs.writeFileSync("output.html", document.body.innerHTML, "utf8")
```
