# Simple email-only auth system in Phoenix

Passwords are so 2018.

The broad approach is described well here: https://lukeplant.me.uk/blog/posts/a-simple-passwordless-email-only-login-system/. That article notes a few important security considerations:

  - The "send me an email link" endpoint must not fetch the user record. Behavior must be identical for new vs. existing users, namely it just emails a login link to the requested address.
  - Said login link must be signed and must expire.
  - The "confirm this address" endpoint (reached by clicking the emailed login link) must never render an HTML page. It must always redirect. This mitigates the risk inherent in including a replayable token in a GET request.
  - There must be a way for the user to log out, which destroys all their login sessions across all devices. This is what I use `user.session_token` for.


## User schema

(Adapt as needed if you already have a User schema.)

Create the users table:

```rb
defmodule Worldviews.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :session_token, :string, null: false
      add :last_logged_in_at, :utc_datetime
      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
```

Create or update a context to house your User schema, as well as helpers for writing and reading login tokens. (See snippet `context.ex`)

Define the User schema with changeset, logic for default token, and filter system. (See snippet `user.ex`)


## Pages / endpoints / controllers / routes

Define `lib/...web/plugs/auth_plugs.ex`. (See snippet)

Define `lib/...web/controllers/auth_controller.ex`. (See snippet)


## Set up email system (Bamboo)

Add bamboo and bamboo_smtp deps to `mix.exs`:

```rb
  {:bamboo, "~> 1.3"},
  {:bamboo_smtp, "~> 2.0"}
```

Configure Bamboo in `dev.exs`:

```rb
# Sent emails are captured in a local process for later inspection.
# Example:
#   MyApp.AdminEmails.unknown_heats() |> MyApp.Mailer.deliver_now()
#   Bamboo.SentEmail.all() # => a list having one %Bamboo.Email{} struct
config :my_app, MyApp.Mailer, adapter: Bamboo.LocalAdapter
```

Configure Bamboo in `test.exs`:

```rb
config :my_app, MyApp.Mailer, adapter: Bamboo.LocalAdapter
```

Configure Bamboo in `prod.exs` using SMTP credentials by a provider like Mailgun:

```rb
# See https://hexdocs.pm/bamboo_smtp/Bamboo.SMTPAdapter.html#module-example-config
config :my_app, MyApp.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: System.get_env("SMTP_SERVER") || raise("Missing env: SMTP_SERVER"),
  username: System.get_env("SMTP_USERNAME") || raise("Missing env: SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD") || raise("Missing env: SMTP_PASSWORD"),
  port: 587
```

Define a mailer mobule in `lib/my_app/mailer.ex`:

```rb
defmodule MyApp.Mailer do
  use Bamboo.Mailer, otp_app: :my_app
end
```

Define one or more email modules that contain a function for building each Email that will be sent:

```rb
# In for ex. lib/my_app/emails/admin_emails.ex
defmodule MyApp.AdminEmails do
  import Bamboo.Email
  use Bamboo.Phoenix, view: MyAppWeb.AdminEmailsView

  def unknown_heats(entries) do
    new_email()
    |> to("hunt.topher@gmail.com")
    |> from("myapp-noreply@topherhunt.com")
    |> subject("[MyApp] Warning: New entries with unknown heats")
    |> put_html_layout({MyAppWeb.LayoutView, "email.html"})
    |> render("unknown_heats.html", entries: entries)
  end
end
```

This email uses a custom layout which we'll define in `lib/...web/templates/layout/email.html.eex`:

```
<html>
  <head>
    <style>
    </style>
  </head>
  <body>
    <%= render @view_module, @view_template, assigns %>
  </body>
</html>
```

Now in your controller, `iex`, or other code, you can build and send an email like this:

```rb
MyApp.AdminEmails.unknown_heats() |> MyApp.Mailer.deliver_now()
```

In dev, you can inspect all sent emails like this:

```rb
Bamboo.SentEmail.all()
# See Hexdocs Bamboo.SentEmail for more detail
```

In tests, you can make assertions about what emails were or weren't sent like this:
(assuming you're using LocalAdapter in your test suite, _contrary_ to official docs)

```rb
defmodule MyApp.SomeModuleTest do
  use MyApp.DataCase

  setup do
    # Clear all emails sent by previous tests.
    # NOT compatible with async tests.
    Bamboo.SentEmail.reset()
  end

  test "the thing sends an email" do
    TargetModule.do_thing()

    emails = Bamboo.SentEmail.all()
    assert length(emails) == 1
    [email] = emails
    assert email.subject =~ "Warning: New entries with unknown heats"
    assert email.to == [nil: "topher@topherhunt.com"]
    assert email.html_body =~ "uncategorized heats were added to MyApp this past week"
  end

  test "the other thing does not send an email" do
    TargetModule.do_other_thing()

    assert Bamboo.SentEmail.all() == []
  end
end
```
