# Testing

## General philosophy

- Tests should give cursory coverage of all code pathways, but shouldn't aim to check every little behavior that we're delivering. The primary purpose of tests is to sanity check the main code pathways and catch regressions. e.g. we test that a user can update their profile, but we don't care to individually check that each field in the profile form works.
- The test suite does not replace manual smoke testing & sanity checks.
- Aim for a consistent, well-organized, and easy-to-read test suite with a reasonable, even, and concise level of coverage. Don't aim for 100% coverage of every detail. But do add more thorough coverage for any logic or failure cases that you're specifically worried about.
- The test suite should be structured intentionally and have a consistent approach & philosophy. It shouldn't be grown organically. An organically-grown test suite is messy, inconsistent, and hard to navigate.
- Use helper methods / modules liberally to keep tests brief and readable.

## Controller tests

Controller / request tests are the main focus of my test suite. There should be a test for every controller endpoint and for each main path available to it.

Tests should cover each pathway, and each important side effect, of each endpoint.

## Unit tests

Test judiciously, focusing on non-trivial custom logic.

In Phoenix, just testing each context's public API should be enough.

## Integration / feature tests

Feature tests are brief, high-level "client demos" that smoke-test each notable feature or area in the application. Structure each one as though you're giving a one-minute demo to Elon Musk: only show off the most important behavior, and keep it as brief as possible.

Put each feature test in its own file. Generally there will be one (often multiple-paragraph) feature test per CRUD interface / major controller.

Every feature test should start by navigating to the homepage. Don't navigate directly to other pages unless necessary.

