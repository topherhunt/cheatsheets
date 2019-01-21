# Services

Here's a simple pattern for organizing logic into services. Each service is called by a standard `ServiceClassName.call(params)` syntax, often performs side effects, and may return a result. Name each service similar to a method name.

I'm not using a `Services::` namespace because Rails autoloading hell.

## How to install it

In an initializer, autoload all the service files:
```ruby
Dir["#{Rails.root}/app/services/**/*.rb"].each { |f| require f }
```

Add `app/services/base_service.rb`:

```ruby
class BaseService
  def self.call(*args)
    self.new.call(*args)
  end

  def log(sev = :info, message)
    raise "Unknown severity #{sev}!" unless sev.to_s.in?(%w(info warn error))
    Rails.logger.send(sev, "#{self.class}: #{message}")
  end
end
```

Add your service class, e.g. `app/services/find_or_create_user.rb`:

```ruby
class FindOrCreateUser < BaseService
  def call(auth:)
    uid = auth.uid
    if user = User.find_by(auth0_uid: uid)
      user
    else
      name = auth.info.name
      image_url = auth.info.image
      user = User.create!(auth0_uid: uid, name: name, image: image_url)
      ensure_image_filename(user, image_url)
      user
    end
  end

  def ensure_image_filename(user, image_url)
    if user.image_file_name.blank?
      user.image_file_name = image_url.match(/[^\/]+\z/)[0]
      log :warn, "Paperclip failed to parse filename from url #{image_url}."
    end
  end
end
```

Then call it:
```ruby
user = FindOrCreateUser.call(auth: request.env["omniauth.auth"])
```
