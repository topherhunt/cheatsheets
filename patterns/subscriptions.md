# Event subscription systems

First off, I haven't yet seen a scenario where event subscriptions are unambiguously necessary. In places where they're used abundantly (e.g. GlassFrog currently has 3 separate subscription systems!), I feel the code would be clearer and more streamlined without them.

If I have code that's complex enough to need an event subscription model, it must be async. Subscriber notifications are queued up and called async one at a time. That way, subscriptions don't bog down the main execution. This means subscriptions can't be used for highly coupled logic (ie. things that need to happen immediately, as part of this request / "transaction"); only for semi-related updates. I think it's important to keep a strong boundary between what's part of the main action and what's a follow-up subscribed action.
