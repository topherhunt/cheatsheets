# Ruby tips


## Files (reading & writing)

Read a file:

```rb
# Load the whole file into a string
IO.read(filename)

# Loop over each line (performant; doesn't load entire file into memory)
IO.foreach(filename) { |line| puts "The line is: #{line}" }
```

Write to a file (overwrite current contents):

```rb
IO.write("filename.txt", "Contents")
```

Write to file (append to current contents):

```rb
File.open(filename, 'a') { |f| f.write "Some appended text\n" }
```

List all files in a directory:

```rb
Dir.glob("#{Rails.root}/app/views/manuals/*.html").map { |str| File.basename(str) }
```


## Date & time best practices

(Some of these idioms rely on Rails ActiveSupport)

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


## Method source introspection

Any method that's used in a specific context of the code that you could `pry` into, you can a) determine where that method is defined (what file & line) and b) view the full source code in-context:

```
# in some pry context that responds to `#where`
method(:where).source_location
method(:where).source
```

There's also `#instance_method` which lets you access instance variables of a given class.


## Frozen string literals

You can freeze all strings _in this file_ using the magic comment:

```ruby
# frozen_string_literal: true
```
