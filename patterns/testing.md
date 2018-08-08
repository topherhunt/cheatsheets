# Testing

## General rationale

- It's more important that the test suite is consistent, reliable, and well-organized, than that it catches every possible (or actual) bug. A well-ordered, consistent test suite will catch enough bugs, whereas a suite that grows organically to cover all empirically discovered breakage will become harder to understand, navigate, and maintain over time.
- Bugs in the controller & view layers are most likely to produce exceptions rather than to lead to incorrect (but exception-less) behavior. So generally my controller tests don't need to paranoidly check that each page displays the right content. In most cases, it's enough to just check that the page renders at all (e.g. correct status code), plus check any obvious expected side effects (e.g. a record was created).

## Controller tests

Controller / request tests are the main focus of my test suite. There should be a test for every controller endpoint and for each main path available to it.

If a controller action seems to require more than 2 tests, consider whether the action is doing too much; could that branching be extracted to a Context or a helper function?

## Unit tests

Test judiciously, focusing on non-trivial custom logic.

In Phoenix, just testing each context's public API should be enough.

## Integration / feature tests

Feature tests are brief, high-level "client demos" that smoke-test each notable feature or area in the application. Structure each one as though you're giving a one-minute demo to Elon Musk: only show off the most important behavior, and keep it as brief as possible.

Put each feature test in its own file. Generally there will be one (often multiple-paragraph) feature test per CRUD interface / major controller.

Every feature test should start by navigating to the homepage. Don't navigate directly to other pages unless necessary.

## Tips

- Use helper methods / modules liberally to keep tests brief and readable.
