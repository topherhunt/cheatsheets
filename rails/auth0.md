# How to set up Auth0 integration on Rails

This is a download of my experience switching from Devise self-hosted auth to Auth0 on Thriveability Lab.


## Configuring the Auth0 account

- Sign up on Auth0, create a namespace ("tenant"), and create an application

- Referring to the Auth0 application's settings page, set three env vars in the Rails app: `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`, and `AUTH0_CLIENT_SECRET`

- In the Auth0 app settings page, add the "Allowed callback URLs" (valid redirects after login), e.g. `http://localhost:3000/auth/auth0_callback`. Also set the "Allowed logout URLs" (valid redirects after logout), e.g. `http://localhost:3000/`.

- In the Auth0 dashboard, under Connections, enable the Database "Username-Password-Authentication" connection. Enable "Requires username".

- In the Auth0 dashboard, under Connections, enable the Social connections for Google and Facebook. For each, make sure you enable the email scope (if email address is needed by the app). For each provider, you'll need to create a developer app integration then fill in the "Client ID" and "Client Secret". See the link, "How to obtain a client ID".


## The Rails code


### Model & dependencies

- Remove any gems and logic related to Devise or OmniAuth.

- Add gems `omniauth` and `omniauth-auth0`

- Remove all User fields related to Devise sessions. Then add these fields back:
  - `auth0_uid` (string, not null, unique indexed)
  - `last_signed_in_at` (datetime)
  - `email` (optional; can require it, but can't assume that it's unique)

- Configure OmniAuth to hook into your Auth0 application:

```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :auth0, # This invisibly defines a redirect: /auth/oauth0 => Auth0's login page
    ENV["AUTH0_CLIENT_ID"],
    ENV["AUTH0_CLIENT_SECRET"],
    ENV["AUTH0_DOMAIN"],
    callback_path: "/auth/auth0_callback", # Auth0 redirects to here after login
    # OpenID scopes - see https://auth0.com/docs/scopes/current/oidc-scopes
    authorize_params: {scope: "openid profile email"}
  )
end
```


### Controllers & services

- Add 3 new routes:

```ruby
# config/routes.rb
  get "auth/auth0_callback" => "auth#auth0_callback"
  get "auth/logout" => "auth#logout", as: "logout"
  get "auth/force_login/:user_id" => "auth#force_login", as: "force_login"
```

- In `ApplicationController`, write your own session-related helpers:

```ruby
# application_controller.rb

  before_filter :load_current_user
  helper_method :current_user

  #
  # Auth helpers
  #

  def sign_in!(user)
    # We don't expire session. You stay logged in until you log out or close browser.
    session[:user_id] = user.id
    user.update!(last_signed_in_at: Time.current)
    @current_user = user
  end

  def load_current_user
    if session[:user_id]
      if @current_user = User.find_by(id: session[:user_id])
        # Great, you're logged in.
      else
        Rails.logger.warn "Resetting invalid session user_id #{session[:user_id]}."
        reset_session
        redirect_to root_path
      end
    end
  end

  def current_user
    @current_user
  end

  def require_logged_in
    unless current_user
      if request.method == "GET"
        session[:return_to] = request.original_url
      else
        session[:return_to] = request.referer
      end
      redirect_to root_path, alert: "You must be logged in to take that action."
    end
  end
```

- Add `AuthController`:

```ruby
# auth_controller.rb
class AuthController < ApplicationController
  before_filter :require_not_logged_in, only: [:auth0_callback]

  # On successful auth, Auth0 redirects the user back here. The Omniauth gem
  # registers a magical middleware that exchanges the auth token for the userinfo
  # (see config/initializers/omniauth.rb) and puts the userinfo in request.env.
  def auth0_callback
    user = Services::FindOrCreateUserFromAuth.call(auth: request.env["omniauth.auth"])
    sign_in! user
    redirect_to session.delete(:return_to) || root_path
  end

  # Logs out of both the app and Auth0 session - see https://auth0.com/docs/logout
  def logout
    reset_session
    redirect_to auth0_logout_url
  end

  # Auth0 lets the admin force-login as any registered user, but this is useful
  # for tests etc. too.
  def force_login
    if params[:password] == ENV["FORCE_LOGIN_PASSWORD"]
      user = User.find(params[:user_id])
      log :warn, "#force_login succeeded, logging in as user #{user.id}."
      sign_in! user # Note: this will update the timestamp like normal signins
      redirect_to root_path, notice: "You're logged in as #{user.name}."
    else
      sleep 1 # prevent brute forcing
      raise "#force_login called with wrong password! Provided password was: #{params[:password]}"
    end
  end

  private

  def auth0_logout_url
    domain = ENV.fetch("AUTH0_DOMAIN")
    returnTo = CGI.escape(root_url)
    client_id = ENV.fetch("AUTH0_CLIENT_ID")
    "https://#{domain}/v2/logout?returnTo=#{returnTo}&client_id=#{client_id}"
  end
end
```

- Add the `BaseService `pattern and `Services::FindOrCreateUserFromAuth`:
  (this logic assumes we're storing name, email, and image attachment)

```ruby
# app/services/base_service.rb (the base class for my Service pattern)
module Services
  class BaseService
    def self.call(*args)
      self.new.call(*args)
    end

    def log(sev = :info, message)
      raise "Unknown severity #{sev}!" unless sev.to_s.in?(%w(info warn error))
      Rails.logger.send(sev, "#{self.class}: #{message}")
    end
  end
end
```

```ruby
# app/services/find_or_create_user_from_auth.rb
module Services
  class FindOrCreateUserFromAuth < BaseService
    def call(auth:)
      # See https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
      raise "Expected auth.uid to be present!" unless auth.uid.present?
      uid = auth.uid || raise("UID is required")
      name = get_name(auth) || raise("Name is required")
      email = auth.info.email || raise("Email is required")
      image_url = auth.info.image || raise("Expected image to always be present")

      if user = User.find_by(auth0_uid: uid)
        log :info, "Authed known user (id: #{user.id}, uid: #{uid}, name: #{user.name})"
        user
      else
        user = User.new(auth0_uid: uid, name: name, email: email, image: image_url)
        ensure_image_filename(user, image_url)
        user.save!
        log :info, "Authed new user (id: #{user.id}, uid: #{uid}, "\
          "name: #{user.name}, email: #{user.email})"
        user
      end
    rescue => e
      raise "Invalid auth data: #{e}. The full auth data from Auth0: #{auth.to_json}"
    end

    def get_name(auth)
      # The Auth0 database connection sets `name` to the email address, weirdly
      if auth.info.name.include?("@")
        auth.info.nickname
      else
        auth.info.name
      end
    end

    def ensure_image_filename(user, image_url)
      # Work around a weird Paperclip bug where the filename gets blanked out
      if image_url.present? && user.image_file_name.blank?
        filename = image_url.match(/[^\/]+\z/)[0]
        log :warn, "Paperclip failed to parse filename from image url #{image_url.inspect}, defaulting to #{filename.inspect}."
        user.image_file_name = filename
      end
    end
  end
end
```

- Add the login & logout links in the navbar (adjust markup as needed):

```
- if current_user
  %div= current_user.name
  %div= link_to "My Profile", user_path(current_user)
  %div= link_to "Log out", logout_url, class: "text-danger"
- else
  %div= link_to "Log in", auth0_login_url
```


### Tests

- `AuthControllerTest`:

```ruby
# test/controllers/auth_controller_test.rb
require "test_helper"

class AuthControllerTest < ActionController::TestCase
  tests AuthController

  context "#auth0_callback" do
    # TODO: This test doesn't cover Omniauth's logic, which uses the provided
    # Auth0 token to look up and provide the info on the logged-in user.
    it "logs in the user found or created by the service" do
      user = create :user
      Services::FindOrCreateUserFromAuth.stubs(call: user)

      get :auth0_callback

      assert_equals user.id, session[:user_id]
      assert_redirected_to root_path
    end
  end

  context "#logout" do
    it "logs out a logged-in user" do
      user = create :user
      sign_in user
      assert_equals user.id, session[:user_id]

      get :logout

      assert_equals nil, session[:user_id]
      assert_redirected_to /topherhunt.auth0.com/
    end
  end

  context "#force_login" do
    it "works if you give a valid password" do
      user = create :user

      get :force_login, user_id: user.id, password: ENV['FORCE_LOGIN_PASSWORD']

      assert_equals user.id, session[:user_id]
      assert_redirected_to root_path
    end

    it "rejects if you give an invalid password" do
      user = create :user

      assert_raise(RuntimeError) do
        get :force_login, user_id: user.id, password: ENV['FORCE_LOGIN_PASSWORD'] + 'z'
      end
    end
  end
end
```

- Add session-related controller test helpers:

```ruby
  def sign_in(user)
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
  end
```

- Add session-related integration test helpers:

```ruby
  def sign_in(user)
    visit force_login_path(user.id, password: ENV["FORCE_LOGIN_PASSWORD"])
  end

  def sign_out
    visit "/logout"
  end
```


## Caveats

- The above logic doesn't support updating your email address. See the "email confirmation" guide to set that up.
