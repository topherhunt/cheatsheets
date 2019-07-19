# Elm basics


## References

  * https://guide.elm-lang.org/
  * When I'm stuck, visit [the Elm Slack](http://elmlang.herokuapp.com/) and ask about it
  * https://package.elm-lang.org/ - Elm packages
  * https://package.elm-lang.org/packages/elm/core/latest/
  * https://elm-lang.org/0.19.0/init
  * Basic syntax of the Elm language: https://guide.elm-lang.org/core_language.html


## Tools

  * `elm repl` - interactive terminal
  * `elm reactor` - stands up a simple server to test individual elm files/modules.
    Start the reactor in your Elm root folder, then go to localhost:8000.
  * `elm make` - compiles Elm code to JS/HTML
  * `elm install` - install Elm packages. (similar to npm)


## The Elm architecture

Architecture for building web apps. Supports modularity, code reuse, testing, and safety.
This architecture emerges naturally; the features of the language seem to steer everyone towards it.
You can use or imitate the Elm architecture even if you're working in another language.

The basic pattern:

  * model - the state ofy our app
  * update - a way to update your state
  * view - a way to render current state as HTML

Standard initial skeleton:

```elm
import Html exposing (..)


-- MODEL


type alias Model = { ... }


-- UPDATE


type Msg = Reset | ...

update : Msg -> Model -> Model
update msg model =
  case msg of
    Reset -> ...
    ...


-- VIEW

view : Model -> Html Msg
view model =
  ...

```

