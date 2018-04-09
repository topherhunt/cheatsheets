# Ruby

## Method source introspection

Any method that's used in a specific context of the code that you could `pry` into, you can a) determine where that method is defined (what file & line) and b) view the full source code in-context:

```
# in some pry context that responds to `#where`
method(:where).source_location
method(:where).source
```

There's also `#instance_method` which lets you access instance variables of a given class.
