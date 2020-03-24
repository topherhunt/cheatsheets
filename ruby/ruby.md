# Ruby tips


## Strings

Some ways to create a string:

```rb

'single quotes'

"double quotes"

%q{'\"oeuoeu}

""" blah """

```


## Reading & writing files

```rb
# Read a file into a string, all at once
IO.read(filename)

# Read and process a file line by line (avoids loading the whole thing into memory)
IO.foreach(filename) { |line| puts "The line is: #{line}" }

# Write to a file (overwrite current contents):
IO.write("filename.txt", "Contents")

# Write to file (append to current contents):
File.open(filename, 'a') { |f| f.write "Some appended text\n" }

# List all files in a directory:
Dir.glob("#{Rails.root}/app/views/manuals/*.html").map { |str| File.basename(str) }
```


## Date & time best practices

(Some of these idioms rely on Rails ActiveSupport)

DO use:

- `Time.zone.now` - explicitly give time in local tz
- `Time#to_date` - explicitly give date relative to the specified tz
- `Time#utc` - explicitly give time expressed in UTC
- `2.days.ago` / `3.minutes.from_now` etc. are always in local tz
- `Time.now.utc.to_date`

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


## Sorting

All the following formats return a NEW array and do not mutate the original array.

```rb
# Simple sort by one value:
array.sort_by(&:length)

# Or in block format:
array.sort_by { |item| item.foo.bar }

# Sort by multiple values: (sort by the first, then by the second, etc.)
array = [{x: nil, y: 2, z: 2}, {x: nil, y: 1, z: 1}]
array.sort { |a, b| [a[:x], a[:y], a[:z]] <=> [b[:x], b[:y], b[:z]] }

# NOTE: This does NOT work when present values are compared against nil. So make sure
# that all compared values || to something non-nil! e.g. this will raise an exception:
array = [{x: nil, y: 2, z: 2}, {x: 1, y: 1, z: 1}]
array.sort { |a, b| [a[:x], a[:y], a[:z]] <=> [b[:x], b[:y], b[:z]] }
```
