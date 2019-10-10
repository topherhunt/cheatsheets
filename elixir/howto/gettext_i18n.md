# I18n / translation of a Phoenix app using Gettext

is pretty straightforward.

  * On each request you need to detect what locale to use. Add a plug to `router.ex`:

    ```rb
    # ADD THIS NEAR THE TOP:
    import WorldviewsWeb.LocalePlugs, only: [detect_locale: 2]

    # ADD THIS PLUG IN THE END OF EACH RELEVANT PIPELINE:
    plug :detect_locale
    ```

  * Write `lib/my_app_web/plugs/locale_plugs.ex`:

    ```rb
    defmodule WorldviewsWeb.LocalePlugs do
      import Plug.Conn, only: [get_session: 2, get_req_header: 2, put_session: 3, halt: 1]
      import Phoenix.Controller, only: [redirect: 2]

      # Decide what locale this request should use.
      # If it's given in a GET param, store it in the session and refresh to clear the param.
      # If it's set in the session, use that. Otherwise fall back to the browser setting or en.
      def detect_locale(conn, _opts) do
        if locale = conn.params["locale"] do
          conn
          |> put_session(:locale, locale)
          |> redirect(to: conn.request_path)
          |> halt()
        else
          session_locale = get_session(conn, :locale)
          browser_locale = get_req_header(conn, "Accept-Language") |> List.first()
          locale = session_locale || browser_locale || "en"

          Gettext.put_locale(WorldviewsWeb.Gettext, locale)
          conn
        end
      end
    end
    ```

  * Add a locale switcher dropdown to your navbar (example uses Bootstrap):

    ```
    <!-- After the user dropdown </li> -->
    <% current_locale = Gettext.get_locale(WorldviewsWeb.Gettext) %>
    <% other_locales = Gettext.known_locales(WorldviewsWeb.Gettext) -- [current_locale] %>
    <li class="nav-item dropdown">
      <a class="nav-link dropdown-toggle" href="#" data-toggle="dropdown">
        <%= flag_for_locale(current_locale) %> <span class="caret"></span>
      </a>
      <div class="dropdown-menu dropdown-menu-right">
        <%= for locale <- other_locales do %>
          <%= link "#{flag_for_locale(locale)} #{String.upcase(locale)}", to: "?locale=#{locale}", class: "dropdown-item" %>
        <% end %>
      </div>
    </li>
    ```

  * Go through your templates etc. and update all user-facing text to use `gettext` calls.
    Try to keep gettext strings compile-time static if possible (not computed).

    ```rb
    # Unless you're in a view or controller, you'll need to import the module first:
    import MyAppWeb.Gettext

    # Simple string example
    <%= gettext("My English text goes here")

    # Example with interpolated variables
    <%= gettext("How much %{object} can an %{actor} chuck", object: @object, actor: @actor)

    # Example of domain-scoped string
    <%= dgettext("countries", "Turkey")

    # Example of pluralizable string
    <%= gettext("Houston, we have a problem", "Houston, we have multiple problems", 3)
    ```

  * Run `mix gettext.extract`. This detects all `gettext` strings in your code and adds them to a "master template" `.pot` file under `priv/gettext/`.

  * Run `mix gettext.merge priv/gettext/` to merge this `.pot` file into all defined locales' `.po` files, adding and removing entries from the .po as necessary.

  * To create a new locale, run `mix gettext.merge priv/gettext --locale nl`.
    (See `mix help gettext.extract` and `mix help gettext.merge` for more detailed usage.)

  * Now you can fill in each locale's translations. Various approaches:

    - Manually edit each `.po` file to in the empty `msgstr ""` strings. DO NOT touch the lines starting with `msgid`, this will cause your entry to not be matched! (Ignore the `en` locale; the EN strings can stay blank as they'll default to using the `msgid` value.)

    - Or you could use https://poedit.net/ to give the translator a friendly UI and some helpful syntax/sanity checks.

    - Or if you're in a rush, use my [machine translation script](https://github.com/topherhunt/topher-utilities/blob/master/machine_translate.rb) which fills in all blank strings in a pofile with Google Cloud Translate translations. (Caveat: the output needs careful manual review & cleanup.)

  * Once you've filled in a page's worth of translations for each locale, start up the dev server and test it out. You should be able to use the navbar switcher to switch locales, and your locale setting should be remembered for as long as you're logged in.
