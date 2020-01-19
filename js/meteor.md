# Meteor.js

Resources:

  * Installing: https://www.meteor.com/install
  * Tutorials: https://www.meteor.com/tutorials
  * Blaze templates: http://blazejs.org/guide/introduction.html
  * UI complete guide: https://guide.meteor.com/ui-ux.html
  * Collections: https://guide.meteor.com/collections.html
  * Code style: https://guide.meteor.com/code-style.html
  * How to structure your application: https://guide.meteor.com/structure.html
  * How mobile builds work: https://guide.meteor.com/mobile.html
  * Building for iOS & Android: https://www.meteor.com/tutorials/blaze/running-on-mobile
  * Drop-in login system: https://docs.meteor.com/packages/accounts-ui.html
  * Testing: https://guide.meteor.com/testing.html

Useful commands:

  * `meteor create my_app [--bare|--minimal|--full|--react]`
  * `meteor` - start the dev server
  * `meteor mongo` - start a db console

Using the db console:

  * `db.tasks.insert({text: "Hello World"})`

Running tests:

  * See https://www.meteor.com/tutorials/blaze/testing for setup
  * `TEST_WATCH=1 meteor test --driver-package meteortesting:mocha`


## Relevance of Meteor.js in 2019

Interesting to note that Meteor bills itself as an easy-to-learn and easy-to-maintain stack for rapid prototyping of mobile apps. Yet today's discussions of what frameworks to use for building mobile apps center on Xamarin, Ionic, RN, and Flutter, and completely ignore Meteor as a candidate. Most "Meteor as a solution for building mobile apps" conversations happened in 2014-2015.

See also this Reddit discussion about migrating off of Meteor due to poor performance when scaling and limitations of Meteor's pubsub system as the architecture grows: https://www.reddit.com/r/javascript/comments/cna8c6/askjs_what_is_a_good_js_tech_stack_to_migrate_a/.

Another Reddit comment (https://www.reddit.com/r/javascript/comments/9t7ih2/i_use_laravel_every_day_for_php_development_what/) mentions that Meteor is great for rapid prototyping, but takes for granted that "it's not particularly scalable", so you need to migrate off of it to some other framework.

Cited alternatives are Vue/React + Apollo + GraphQL (and presumably ReactNative if working on mobile).
