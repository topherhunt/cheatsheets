## Setup

- `mix phoenix new app_name`
- `mix deps.get`
- `npm install`

## Running the server, console, and tasks

- `mix phoenix.server` - start the server
- `mix phoenix.routes`
- `mix phoenix.gen.html Video videos user_id:references:users url:string title:string description:text`
- `mix phoenix_haml.gen.html User users name:string age:integer`
  (generates haml templates, not eex)
- `mix phoenix.gen.model Category categories name:string`
- `iex -S mix` - run iex in context of this project
- `iex -S mix phoenix.server` - run contextual iex AND start the server
- `mix run -e MyApp.Module.execute_some_function("one")`
- `mix run priv/repo/seeds.exs` - you can run any arbitrary .exs script this way

## Mix package commands

- `mix help` - more mix commands
- `mix run path/to/file.exs` - execute an arbitrary script
- `mix hex.docs open --offline hound` - opens the docs for any package

## Environments & env variables

- A default Phoenix app has 3 environments: `:dev`, `:test`, `:prod`. Any dependency applications (e.g. Logger) are always run in `:prod` even if your Phoenix app is in `:dev`.
- Access `Mix.env` (keyword list of all env vars) anywhere in your project code
- Temporarily set/override an env var: `MIX_ENV=test mix run blah/blah.exs`
- Store sensitive env vars in `config/secrets.exs` which *is not* checked into Git. `config/config.exs` should auto-execute `secrets.exs` (loading any vars declared there) if the file is present. You can also define any production config values there too (in a separate, inert map) for safekeeping, and manually transfer them to Heroku etc.

## Plugs

- Module plugs: `init/1` runs at compile time; `call/2` runs at runtime. Call it like:
  `plug Rumbl.Auth` and it will call the right functions.
- Function plugs: `plug :func_name, [args_list]`
- Guard on plugs: `plug :func when action in [:index, :show]`
- You can't plug a function from another module; instead import the function.
- After each plug, Phoenix checks if `conn` is halted. If so, it skips all further plugs (including the controller action) and returns the response as-is.
- Plugs can live anywhere; I'll put mine in `web/plugs/`.

## Conn

- Request fields:
  * host - eg. `"www.example.com"`
  * method - eg. `"GET"`
  * path_info - eg. `["admin", "users"]`
  * req_headers - eg. `[{"content_type", "text/plain"}]`
  * scheme - eg. :https
- Lazy fields:
  * cookies
  * params
  * assigns - you can add any custom data here
  * halted
  * state
- Response fields:
  * resp_body - defaults to `""`
  * resp_cookies
  * resp_headers
  * status

## Controller

- Transforms a request into a response plus side effects. Side effects should be invoked from the controller layer, not the models or views.
- When referencing request `params`, use strings for keys. Only use atoms internally where I'm guaranteed to have a finite number of them; atoms aren't garbage-collected.
- Use `with` so controller actions don't need nested `case` statements.

## Views & templates

- No distinction between templates and partials.
- `render "partial.html", var: "some value"` - call a template (in the inferred view) and pass it vars
- Render a template from the console:
  * `MyApp.UserView.render("index.html", users: []) |> Phoenix.HTML.safe_to_string`
  * `Phoenix.View.render_to_string(Rumbl.UserView, ​"user.html"​, user: user)`
- Links: `Phoenix.HTML.Link.link("name", to: "path", method: :post)`
- Named route helpers: `user_path(@conn, :edit, user.id)` or `user_path(@conn, :index)`
- Best practice: Avoid chaining methods & complex logic in templates. Extract these to view functions. Exceptions raised in the template are hell to troubleshoot.

## Form helpers

```
= form_for @changeset, @action, fn f -> do ...
= label f, :field_name, class: "classes"
= text_input f, :field_name, class: "classes"
= textarea f, :field_name, class: "classes"
= hidden_input f, :field_name, value: "value", class: "classes"
= select f, :field_name, [{"label", val}, ...], prompt: "Select one", class: "classes"
= error_tag f, :field_name
= submit "Submit", class: "classes"
```

## Assets & Brunch

- See http://www.phoenixframework.org/docs/static-assets
- Brunch handles compiling JS, CSS, and images
- `web/static/assets/` is for assets that should not be precompiled. They're just served up wholesale with no alteration.
- `web/static/js/app.js` - manifest ES6 file loaded at the end of `layout.html.eex`
- `web/static/vendor` is for 3rd-party dependencies. These are all auto included at the bottom of layout.html.eex.
- `brunch watch` - auto-runs when you start the phoenix server

## Email

- Use Bamboo and Bamboo.Test
- See the Zb app for thorough examples of mail templates, sending, and both unit tests and integration tests (which turned out to be easy to set up).

## Background jobs

- Verk (https://github.com/edgurgel/verk) is the equivalent of Sidekiq. It builds an abstraction on Elixir's processes system and provides a high-level interface for enqueuing or scheduling jobs backed in Redis, handling errors with exponential backoff, web dashboard, etc.
- Scheduled jobs MUST be idempotent.

## Logging

By default, a Phoenix app spits all logs to STDOUT. In the test environment etc., you can use the `logger_file_backend` library to route logs to a file.
