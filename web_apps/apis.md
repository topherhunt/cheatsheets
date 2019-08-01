# APIs


## REST APIs

References:

  * https://docs.microsoft.com/en-us/azure/architecture/best-practices/api-design

General notes:

  * All requestable collections should be paginated by default. If a collection doesn't need pagination, the reason why not should be noted.

  * Best practice is to avoid nesting routes unless there's a concrete reason why it needs to be nested. (ie. avoid serving api routes that are more complex than `collection/item_id/subcollection`.
