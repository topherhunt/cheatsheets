# Testing with Rspec - especially request specs

#
# Reference:
#
# - https://github.com/rspec/rspec-rails#helpful-rails-matchers
# - https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec
#


#
# Response body
#

response.body
expect(response.body).to include("Widget was successfully created.")


#
# Redirects
#

expect(response).to redirect_to("some_path")
follow_redirect!


#
# Nokogiri
#

# Parse an HTML string into a Nokogiri document:
doc = Nokogiri::HTML("<body><div></div><div id='one'>1<div>and more</div><br>11</div><div id='two'>222</div>333</body>")
# Then you can run css selectors on it:
doc.css('#one') # an array of 2 nodes
doc.css('#one').first.content # just the text w/o any html tags
doc.css('#one').first.inner_html
