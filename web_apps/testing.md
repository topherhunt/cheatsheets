# Testing


## General philosophy

  * I don't do TDD. I only occasionally write my tests first, when the solution is clear and I just need a quick feedback loop. Mostly my tests are aimed at detecting breakage (regression).

  * I focus on controller tests (request tests in Rails) as the main boundary of test coverage. Controller tests should cover every endpoint (action) and generally should have a separate example for each important outcome / logic branch in that action.

  * Where controller tests aren't enough, I'll add judicious unit tests to cover any complex or high-stakes logic, as well as integration tests for any high-stakes JS workflows.

  * Don't aim for 100% coverage. Aim for a *consistent* high level of coverage and an, easy-to-navigate test suite. The test suite should have a predictable, consistent structure to it. It should not feel "organic".

  * Most test examples should be 4-12 lines long. Set up helper methods as necessary to allow the data state to be set up in a concise, highly readable way.
