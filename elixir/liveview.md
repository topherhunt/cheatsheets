# LiveView: tips, resources


## Resources

- https://twitter.com/chris_mccord/status/1106291353670045696
- https://github.com/phoenixframework/phoenix_live_view
- https://blog.smartlogic.io/integrating-phoenix-liveview/
- https://elixirschool.com/blog/phoenix-live-view/
- https://dennisbeatty.com/2019/03/19/how-to-create-a-counter-with-phoenix-live-view.html
- https://www.youtube.com/watch?v=2bipVjOcvdI
- https://www.youtube.com/watch?v=FfpRBh2kWCI

Example LiveView apps:

- https://github.com/chrismccord/phoenix_live_view_example
- https://github.com/zblanco/libu
- https://github.com/kerryb/liveview_demo
- http://palegoldenrod-grown-ibis.gigalixirapp.com/bear_game
- https://github.com/smeade/phoenix_live_view_example


## Tips & notes

- LiveView pubsub broadcasts should include the changed object so receivers don't each have to re-fetch the same record.

- Don't do LiveView partials on static pages. If I need LV on a page, make the whole page the LV.


## Code samples


### A LiveView from RTL (no longer needed):

```ruby
    defmodule RTLWeb.Manage.ProjectsListLiveview do
      use Phoenix.LiveView
      use Phoenix.HTML
      require Logger

      def mount(%{current_user: current_user}, socket) do
        if connected?(socket), do: RTL.Projects.subscribe_to_all_projects()

        socket = socket
        |> assign(:current_user, current_user)
        |> assign(:projects, get_projects(socket))

        {:ok, socket}
      end

      def render(assigns) do
        RTLWeb.Manage.ProjectView.render("list.html", assigns)
      end

      # Listen for a client-side event
      # def handle_event("delete_video" = type, id, socket) do
      #   log "handle_event called with #{type}, #{id}."
      #   Videos.get_video!(id) |> Videos.delete_video!()
      #   {:noreply, socket}
      # end

      # Listen for any relevant pubsub notifications
      def handle_info({RTL.Projects, _event} = payload, socket) do
        log "handle_info called with #{inspect(payload)}."
        {:noreply, assign(socket, :projects, get_projects(socket))}
      end

      defp get_projects(socket) do
        user = socket.assigns.current_user

        if RTL.Accounts.is_superadmin?(user) do
          RTL.Projects.get_projects()
        else
          RTL.Projects.get_projects(having_admin: user)
        end
      end

      defp log(message), do: Logger.info("Manage.ProjectsListLiveview: #{message}")
    end
```

