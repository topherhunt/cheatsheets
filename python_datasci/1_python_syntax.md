# Python syntax


## Basic

- semantic whitespace / indentation
- `None` instead of `nil`
- colon at the end of defs and ifs
- params can be either positional or keyword, or mixed
- you can assign a function: `a = add_numbers`
- `type(value)` to return the object's type (str, int, float, function, NoneType, etc.)
- When you assign a value, the expression doesn't return anything.
- Functions return None unless you explicitly call `return`.
- Optional function params must come at the end of the signature (after pos.)


## Strings

- Strings are immutable. Strings can use either `"` or `'`.
- Slice a string: `"topher"[1]`, `"topher"[0:4]`, `"topher"[-1]`, `"topher"[3:]`
- You can use `+`, `*`, and `in` with strings same as lists.
- `"topher hunt".split(" ")` same as in Ruby
- Convert objects to string before concatenating etc: `str(2)`
- There's no built-in string injection, rather you call `"some string {} with injects {}".format(value1, value2, ...)`
- All strings are unicode.


## Ints & floats

- Set float precision using a formatting string like `"%.2f"`
- Convert a string to a number: `float("1.2")` or `int("45")`


## Lists & tuples

- tuples use parens: `(1, 'a', 4.0)`. **Tuples are immutable.**
- Lists are like in Elixir & Ruby. They're mutable: you can append etc.
- List comprehension: `for item in a_list:`. (can take a list or tuple)
- You can also use a while loop and increment over `i` like in C.
- Concatenate lists (or tuples): `[1, 2] + [3, 4]`
- Repeat lists: `[1, 2, 3] * 1000`
- Check if a value is in a list: `3 in [1, 2, 3]`. You can also use `in` to search for a substring in a string.
- assign multiple variables from a list: `a, b, c = list` (fails if the list or tuple length doesn't match the # of vars to assign)

How to `sum` a list:

    sum(float(r['mpg_city']) for r in records)

How to get a set of unique items in a list: (use the `for` to map each item)

    cylinders = set(d['cyl'] for d in mpg)


## Dicts

- Dict: `dict = {'a': 1, 'b': 2}`. Keys must be string or another value; no atoms.
- `dict.keys()` and `dict.values()` - get a list of all keys/vals in dict
- `dict.items()` - get a list of key/value tuples. This can be used in a list comprehension e.g. `for k, v in dict.items():`


## Working with csv files

    import csv
    with open('mpg.csv') as csvfile:
      records = list(csv.DictReader(csvfile))
      print(records[0].keys())


## Dates & times

The `time` module works with epoch-based integer timestamps. The `datetime` module works with "smarter" more structured dates. Examples:

    dt_from_timestamp = dt.datetime.fromtimestamp(123456789)
    delta = dt.timedelta(days = 98.5)
    several_months_ago = dt.date.today() - delta


## Objects & classes

- Python has classes, but they work a bit differently from Ruby.
- Implicit constructor `__init__` but it's rarely used.
- Inst vars are publicly accessible by default, you don't need an accessor.
- Python will raise if you try to access an inst var that hasn't been set yet.
- You can declare "class variables" but they're really just default values for inst vars, and can be overridden.


## Functional programming

- `map`s are written backwards and are lazy evaluated. You pass in the function to map over, then the list(s) as params, then that returns a Map object which you must then iterate over. This lazy evaluation is great for performantly processing large amounts of data.
- Use `lambda` to create an anonymous function assigned to a var. Each lambda can only be one expression long.


## List comprehensions

List comprehensions let you compactly filter down a list to certain elements and/or transform them. This is often more performant than using `for` and `list.append()` to manually build up a new list. e.g.:

    even_nums = [num for num in range(0,1000) if num % 2 == 0]

And you can nest your `for` statements too (yuck):

    all_products = [i * j for i in range(10) for j in range(10)]
    possible_usernames = [l1+l2+d1+d2 for l1 in letters for l2 in letters for d1 in digits for d2 in digits]


## Magic functions (Jupyter)

Functions that start with `%` and `%%` are metaprogrammy.

Example: `%%timeit` will benchmark the code you run in that Jupyter cell:

    %%timeit -n 100
    sum = 0
    for item in some_series:
      sum += item

You can also execute some shell commands using `!` like this:

    !cat olympics.csv


