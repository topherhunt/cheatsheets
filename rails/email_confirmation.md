# Hand-rolled email confirmation system

On Thriveability Lab, I briefly tried adding an email confirmation system to allow you to change your email address and prove that you own it. This turned out to be unnecessary for now so I ripped it out. But if I want to implement an email confirmation system in a Rails, non-Devise setting (that app uses Auth0 now), here's how I did it.

New route for the confirm_email endpoint:

```ruby
  get "users/:id/confirm_email" => "users#confirm_email", as: "user_confirm_email"
```

UsersController:
- permit param :email
- On update, if email was changed, confirm new email address
- New endpoint UsersController#confirm_email to receive the email link click

```ruby
  def update
    @user = current_user
    if @user.update(user_params)
      confirm_new_email_address if email_was_changed?
      redirect_to user_path(@user), notice: "Your changes are saved."
    else
      flash.now.alert = "Unable to save your changes. See error messages below."
      render 'edit'
    end
  end

  def confirm_email
    @user = User.find(params[:id])
    if valid_confirmation_token_for_email?(params[:token], @user.email)
      sign_in!(@user)
      @user.update!(email_confirmed_at: Time.now.utc)
      redirect_to user_path(@user), notice: "Thanks! Your email is confirmed."
    else
      redirect_to root_path, alert: "That email confirmation token isn't valid."
    end
  end


  private

  def email_was_changed?
    user_params[:email].present?
  end

  def confirm_new_email_address
    @user.update!(email_confirmed_at: nil)
    UserMailer.confirm_new_email_address(@user).deliver_now
  end

  def valid_confirmation_token_for_email?(token, email)
    BCrypt::Password.new(token).is_password?(email)
  end
```

The Users#edit form addition:

```
  .row.row-padded
    .col-sm-4
      = f.label :email
      .hint.small Where should we send notifications about activity in your network? (optional) Your email address isn't visible to anyone and we won't share it.
    .col-sm-8= f.text_field :email, class: "form-control"
```

UserMailer#confirm_new_email_address:
- Generate a Bcrypt token from the email address
- The email contains a link to users#confirm_email, with that token as param

```ruby
class UserMailer < ApplicationMailer
  def confirm_new_email_address(user)
    @user = user
    @token = BCrypt::Password.create(@user.email).to_s

    mail(
      to: @user.email,
      from: ENV.fetch('SUPPORT_EMAIL'),
      subject: "#{app_name}: Please confirm your email address")
  end

  def app_name
    "Thrivability Lab"
  end
end

# The view:


```

The mailer view:

```
  %p Hello #{@user.name},

  %p We sent this message because you have updated your email address for #{link_to "Thrivability Lab", ENV["HOSTNAME"]} to <strong>#{@user.email}</strong>. If this is correct, please confirm the address by clicking on the link below.

  %p= link_to "Click here to confirm your email", user_confirm_email_url(@user, token: @token)

  %p If you did not make this change or you don't know what Thrivability Lab is, you can safely ignore this message.
```

UserControllerTests: Add coverage of the email confirmation related logic

```ruby
  context "#update" do
    # ...

    it "sends the email confirmation mailing if email was changed" do
      sign_in @user
      emails.clear
      patch :update, id: @user.id, user: {email: "daffy@example.com"}

      assert_equals 1, emails.count
      assert_equals ["daffy@example.com"], emails.last.to
      assert emails.last.subject.include?("Please confirm your email address")
      token = find_confirmation_token(emails.last.body)
      assert valid_token_for_email?(token, "daffy@example.com")
    end

    it "doesn't send the confirmation if email wasn't changed or was blank" do
      sign_in @user
      emails.clear
      patch :update, id: @user.id, user: {name: "Daffy"}

      assert_equals 0, emails.count
    end

    def find_confirmation_token(body)
      token = body.match(/\?token=(.+)"/)&.captures&.first
      CGI.unescape(token)
    end

    def valid_token_for_email?(token, email)
      BCrypt::Password.new(token).is_password?(email)
    end
  end

  context "#confirm_email" do
    it "confirms and logs in the user if token is valid" do
      user = create :user, email: "whatever", email_confirmed_at: nil
      token = BCrypt::Password.create(user.email).to_s

      get :confirm_email, id: user.id, token: token

      assert_equals user.id, session[:user_id]
      assert user.reload.email_confirmed_at.present?
      assert_redirected_to user_path(user)
    end

    it "rejects invalid tokens" do
      user = create :user, email: "whatever", email_confirmed_at: nil
      token = BCrypt::Password.create("other_email").to_s

      get :confirm_email, id: user.id, token: token

      assert session[:user_id].nil?
      assert user.reload.email_confirmed_at.nil?
      assert_redirected_to root_path
    end
  end
```
