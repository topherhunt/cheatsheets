# Date & time best practices

DO use:

- `Time.zone.now` - explicitly give time in local tz
- `Time#to_date` - explicitly give date relative to the specified tz
- `Time#utc` - explicitly give time expressed in UTC
- `2.days.ago` / `3.minutes.from_now` etc. are always in local tz

DO NOT use:

- `Time.now` / `Time.current` - these easily obscure which tz was intended
- `Date.today` / `Date.tomorrow` - very inconsistent behavior; avoid these
- `Time#to_s(:db)` - when arg is provided, it implicitly converts to UTC
- `Date#to_time` - ambiguous usage