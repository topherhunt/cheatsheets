# LiveView: tips, resources


## Resources

- https://twitter.com/chris_mccord/status/1106291353670045696
- https://github.com/phoenixframework/phoenix_live_view
- https://blog.smartlogic.io/integrating-phoenix-liveview/
- https://elixirschool.com/blog/phoenix-live-view/
- https://dennisbeatty.com/2019/03/19/how-to-create-a-counter-with-phoenix-live-view.html
- https://www.youtube.com/watch?v=2bipVjOcvdI
- https://www.youtube.com/watch?v=FfpRBh2kWCI
- Debounce: https://dev.to/tizpuppi/phoenix-live-view-debounce-4icf

Example LiveView apps:

- https://github.com/chrismccord/phoenix_live_view_example
- https://github.com/zblanco/libu
- https://github.com/kerryb/liveview_demo
- http://palegoldenrod-grown-ibis.gigalixirapp.com/bear_game
- https://github.com/smeade/phoenix_live_view_example


## Tips

  * LiveView pubsub broadcasts should include the changed object so receivers don't each have to re-fetch the same record.

  * Don't put nested data (eg. Ecto records) into the LV session. Keep in mind the session data is sent across the wire when the websocket inits! Keep your session data to scalars as much as possible.

  * If you're rendering a video inside a LV, watch out for crazy high CPU usage, especially if the LV will rerender frequently. Chrome doesn't seem to like this. Move the video to outside the LV boundary and the issue should resolve.

  * JY worked out a nice system for adding contenteditable spans that autosave immediately using Liveview and JS hooks. (see Tealdog)

  * When rendering partials inside a .leex template, pass all assigns via the `assigns` helper function, rather than passing the specific variables (`@current_user`, `@project` etc). When you pass the @- variables, Liveview sometimes doesn't diff values properly and you can end up with problems rerendering / updating the DOM.

  * If you want to invoke a Liveview event from within JS, there's two options: 1) You can trigger a LV event (eg. a phx-click) from JS by selecting the link element and dispatching a manually-created "click" event to it. 2) using Liveview's JS hooks system, add a function on the global `window` context that will trigger the Liveview event when the function is called. (Tealdog has an example of the latter.)


## Testing LVs

The api for unit testing LVs isn't super stable. Latest version of Phoenix.LiveViewTest recommend using ConnTests that load the associated route rather than manually mounting the LV as an isolated process. I'm unclear how this would work in case of LVs that are rendered as a partial in a static html template.
