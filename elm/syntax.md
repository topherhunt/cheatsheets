# Elm syntax basics

The language is simple: values, functions, lists, tuples, records.

Whitespace is significant. Function bodies etc. must be indented if on separate lines.


## Strings

```
"hello"
"hello" ++ " world" -- concatenate

-- Lots of helper functions, e.g.:

String.length "abc"
=> 3

String.toUpper "abc"
=> "ABC"

String.fromInt 123
=> "123"
```


## Numbers

```
-- Strong distinction btw Number (ints) and Float.
(3 * 4) + 1
10 / 4   -- FLOAT division => 2.5
10 // 4  -- INT division => 2 (floored)
```


## Bools

```
True  -- capitalized
False
True || False
=> True

-- Non-bool values do not have "truthiness". You'll get an error if you use a string etc.
```


## Conditionals

```
-- Must have an explicit `else` declared, or end the if somehow.
if True then "hello" else "nope"
```


## Functions

```
-- Define a function "isNegative" with 1 arg:
-- Function syntax is very parenthesis-free.
isNegative n = n < 0
=> <function> : number -> Bool

-- Call a function:
isNegative -1
=> True

-- Define an anonymous function:
\n -> n < 0

-- Call an anonymous function:
(\n -> n < 0) 4

-- For long functions, have a newline & indent after the signature:
update msg model =
  case msg of
    Increment ->
      model + 1
    Decrement ->
      model - 1

-- You can explicitly define the type signature for a function:
-- (TODO: find a simpler example)
embedHtml : Html Never -> Html msg
embedHtml staticStuff =
  div []
    [ text "hello"
    , Html.map never staticStuff
    ]
```


## Lists

```
-- Linked Lists. Access is O(n). (If you want O(log n) access time, see Array.)
-- All values MUST be of the same type.

people = ["Alice", "Bob", "Charlie"]

-- Lots of helper functions are available, e.g.:
List.isEmpty names
List.length names
List.sort numbers
List.map sqrt [2, 9, 16]
List.map .x points -- for each point record, return the .x value
```


## Tuples

```
-- Tuples hold a fixed number of values. Values can be of any type.
(True, "name accepted!") -- defined using parens
```


## Records

```
-- Like objects in JS or maps in Elixir.
-- Commonly used instead of Tuples in Elm.

point = { x = 3, y = 4 }
=> { x = 3, y = 4 }

point.x
=> 3

-- You can access fields like a function call:
.x point
=> 3

-- You can update EXISTING fields in a record: (returns a new record)
{ point | x = 4 }
=> { x = 10, y = 4 }

-- Other notes:
-- You can't reference undefined fields on a record, it produces an error.
-- You can't update/add undefined fields on a record, nor remove defined fields.
-- Records are duck-typed: usable anywhere as long as the needed fields are present.

-- You can pattern-match records in function signatures:
under70 {age} = age < 70
```


## Types

  * The elm repl will tell you the type of each statement's return value.

  * Functions have types too, describing the input(s) and output(s). Elm will warn you if a function is being passed the wrong type.

Optionally you can explicitly specify the type signature for a function. This is super useful in making sure the logic is receiving/returning exactly the shape you expect it to.

```
view : Model -> Html Msg -- takes a Model input and returns an Html Msg
view model = ... -- the function definition itself
```

  * Normally types are capitalized. When you see a downcased type, it's usually either a type variable (e.g. `List a` for a list of any value type) or a constrained type (e.g. `number` which includes `Int` and `Float` but disallows all other types).

You can create a **type alias** to refer to a custom type by a special name, so you don't have to repeat the explicit type over and over again:

```
type alias User = {name: String, bio: String}

-- In addition to giving you a convenient alias, this also gives you a "record constructor"
-- so you can more easily generate records of this type:

person3 = User "Tom" "Friendly Carpenter"
```

When you define a type alias for a record (e.g. the `User` type above), this also gives you a **record constructor** so you can more efficiently generate records of that type:

You can also define custom types which work like enums:

```
type UserStatus = Regular | Visitor

-- Then you can use your custom type in other types, helping ensure records have valid data
type alias User = { status: UserStatus, name: String }
```

You can also pattern-match on the fields of custom types, though this makes my head hurt:

```
case user of
  Regular name age ->
    name

  Visitor name ->
    name
```

An important type is Maybe. A Maybe has 2 variants: 1) Just a certain value, or 2) Nothing.
Maybe values are useful when you have records with optional fields, e.g.:

```
type alias User = {name: String, age: Maybe Int}
```

But don't over-use Maybe; often there's a more elegant solution.
