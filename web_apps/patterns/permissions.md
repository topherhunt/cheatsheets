# Permissions & authorization

- For simple apps, controller before-action plugs might be adequate.
- For more complex HTML-serving apps, consider a global plug that will abort the request with error if an endpoint wasn't authed. That way you can't forget to apply some authorization check to the request.
- For permission checks that don't happen at the beginning of a page / endpoint request, use this pattern: `current_user.can?(:update_proposal, proposal)`
