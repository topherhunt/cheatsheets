# Logging


## Thorough email logging

In `ApplicationMailer` (or whatever your base mailer is), override `mail` to log the send attempt:

```ruby
def mail(headers, &block)
  log_thorough_details(headers)
  super(headers, &block)
end

private

def log_thorough_details(headers)
  mailer_name = "#{self.class}.#{action_name}"
  subject     = headers[:subject] || '(no subject)'
  recipient   = headers[:to] || '(nobody)'
  Rails.logger.info "Sending mail #{mailer_name} (\"#{subject}\") to #{recipient}"
end
```


## Thorough 1-line request logging

- Set Rails `config.log_level = :info` to hide SQL query logs etc.
- Install [lograge](https://github.com/roidrage/lograge)
- Configure it in an initializer:

```ruby
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    {
      pid: Process.pid,
      ip: event.payload[:ip],
      user: event.payload[:user],
      time: event.time.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      params: event.payload[:params].except(*%w(controller action format id))
    }
  end
  config.lograge.formatter = ->(data) {
    # Data I'm excluding for brevity:
    # - controller=#{data[:controller]}##{data[:action]} (I can infer this)
    # - ip=#{data[:ip]} (Heroku router logs this in case I need it)
    # - "#{data[:time]} "\
    # - "pid=#{data[:pid]} "\
    # Other possible starting chars: █ »
    "■ [#{data[:method]} #{data[:path]}] "\
    "params=#{data[:params]} "\
    "user=#{data[:user]} "\
    "status=#{data[:status]}"\
    "#{data[:location] ? " redirected_to="+data[:location] : ""} "\
    "duration=#{data[:duration]}ms"
  }
end
```

In ApplicationController, add the missing payload metadata:

```ruby
# Add request metadata to Lograge payload (see config/initializers/lograge.rb)
def append_info_to_payload(payload)
  super
  payload[:ip] = request.remote_ip
  payload[:user] = current_user ? "#{current_user.id} (#{current_user.name})" : "none"
end
```

If you use Rack::Timeout, consider disabling its logger:

```ruby
# (in config/initializers/rack_timeout.rb)
if defined?(Rack::Timeout)
  Rack::Timeout::Logger.disable # these are verbose and unnecessary
end
```
