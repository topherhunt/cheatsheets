# Authentication

An app with only light security needs can use my hand-rolled Elixir auth solution.
If an app needs industry-grade security practices (e.g. omniauth signin, email confirmation), I should wire up Auth0.

## Checklist for a secure auth solution

- PWs are hashed and salted
- PW reset tokens shouldn't be stored in the db in the clear, rather they should be hashed same as how passwords are hashed. This way even if an attacker gets a leak of the db, he still can't use the pw reset mechanism to log in as users.
