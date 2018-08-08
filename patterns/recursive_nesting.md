# Recursive nesting

Where possible, err on the side of *not* setting up recursive nesting in persisted state, e.g. in a SQL table. It opens up a bunch of cans of worms that you can often avoid with blunter, less recursive tools.
