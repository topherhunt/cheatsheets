## What makes Phoenix / Elixir worth learning?

- Its emphasis on explicitness; it seems to do away with much or most of Rails "magic" code

- The app config and request lifecycle components are explicitly defined front-and-center, so I'd build a much deeper understanding of and confidence with the various "middleware" involved in a request, whereas that's very opaque to me in Rails

- It imitates the best parts of Ruby and Rails, so at the surface level I should find a lot familiar

- Live-reload for the asset pipeline

- It has first-class support for the latest JS features and for real-time connections (Channels / websockets I think) - a good thing to invest in

- All code is organized into pure functions with only input and output, meaning testing should be more straightforward and more uniform than in Rails

- Insane performance or whatever

- Rails is showing its age. There's things that are poorly thought out, it's starting to run up against architectural double-binds where it can't accommodate change and can't handle certain edge cases as well as I'd like it to.

- People keep saying that Elixir's functional nature makes it easy to decompose, refactor, troubleshoot, and maintain. If I follow certain patterns I can write highly transparent and side-effect-free Ruby/Rails code, but Ruby/Rails doesn't encourage this pattern for the most part, and in some cases Ruby's conventions (if not structure) make it extremely hard to hold to these patterns. Whereas in Elixir the structure of the language enforces this.

- Elixir was built by someone intimate with Ruby and Rails, and the problems R&R developers have run into, and the language was designed to avoid those pitfalls.

- Phoenix is highly agnostic about where you put your files. This means I could organize my models into a custom folder structure that tells a story, rather than being stuck with the monolithic "models/" folder.
