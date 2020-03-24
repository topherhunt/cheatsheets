defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use Plug.ErrorHandler # for Rollbax
  import MyAppWeb.AuthPlugs, only: [load_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_current_user
  end

  # Note: auth relies on the browser cookie session for now, so this isn't a full api.
  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :load_current_user
  end

  # In dev, preview all "sent" emails at localhost:4000/sent_emails
  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/error", PageController, :error
    get "/privacy", PageController, :privacy
    get "/terms", PageController, :terms

    get "/auth/signup", AuthController, :signup
    post "/auth/signup", AuthController, :signup_submit
    get "/auth/login", AuthController, :login
    post "/auth/login", AuthController, :login_submit
    get "/auth/logout", AuthController, :logout
    get "/auth/request_email_confirm", AuthController, :request_email_confirm
    post "/auth/request_email_confirm", AuthController, :request_email_confirm_submit
    get "/auth/confirm_email", AuthController, :confirm_email
    get "/auth/request_password_reset", AuthController, :request_password_reset
    post "/auth/request_password_reset", AuthController, :request_password_reset_submit
    get "/auth/reset_password", AuthController, :reset_password
    post "/auth/reset_password", AuthController, :reset_password_submit

    get "/account/edit", UserController, :edit
    patch "/account/update", UserController, :update
    patch "/account/update_email", UserController, :update_email
  end

  # scope "/api", MyAppWeb, as: :api do
  #   pipe_through :api
  #   get "/groups/:uuid/progress", Api.GroupController, :progress
  #   post "/responses/:uuid/done", Api.ResponseController, :done
  # end

  defp handle_errors(conn, data), do: MyAppWeb.ErrorPlugs.handle_errors(conn, data)
end
