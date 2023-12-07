# State machine

I'm very ambivalent about how I want to handle state machines.

Some considerations:

- As always, I dislike magical code. `aasm` generates hundreds of methods dynamically on your model, creating yet another set of vocabulary you need to hold in your head in order to work with that model optimally.
- `aasm`'s DSL is too much of a straightjacket to (cleanly) model complex workflows. You end up resorting to hacks and clarifying comments that don't sit well.
- `aasm` also has some scary caveats regarding when the `after` blocks will and won't get executed. I don't remember what these were, but they were scary enough that I resolved never to use aasm voluntarily again.
- But you do need more structure than just a mixed bag of methods, intermixed with the rest of your other model junk. That would be a regression.
- Part of my distaste for `aasm` is due to the MAPP's very complex and arguably overly-flexible workflow. That particular workflow, on close inspection, would be better modelled as a set of boolean queries; you just can't model it as a linear progression of states. There's too many edge cases (you might have a stem-scored but not protocol-scored assessment; some assessments will be scored but not coached; you might not have assigned the coach until later steps; some assesments aren't responded online, rather uploaded manually, etc.). So in another, tamer context, I might not have grown such strong distaste for `aasm`.

## One tentative approach to a DSL-free, fully-Ruby state machine:

- The model has a `STATES` constant. It's a hash where each key is a state, and each value is a subhash encoding the allowed transitions from that state, as well as other possible options.
- The model has an `Events` subclass. Each transition event is a *class* method in `Events`, which always returns true or false depending on whether the transition succeeded. (is this adequate?)
- The model has an instance method `#trigger_event(:event_name)`. This calls the corresponding event, as long as the current state permits that event.
