# Rails
#
# Reference:
# - http://www.codefellows.org/blog/this-is-why-learning-rails-is-hard/
#

#
# Cache
#

# Cache any computed/fetched value using Rails' configured cache store
Rails.cache.fetch(key, expires_in: 1.month) { ...heavy expression... }

# Clear the entire cache (useful to put this in an initializer file)
Rails.cache.clear

#
# UJS
#

# Steps:
#
# 1. Create a link with the `remote: true` option. Rails' JS will intercept clicks and send
#    an ajax request to that path with format=".js".
link_to "click here", edit_game_path(game), remote: true
#
# 2. The controller action should have a response available for .js format (either write
#    a .js.erb template or specify a respond_to block with a format.js handler).
def edit
  @game = Game.find(params[:id])
  # implicitly default to edit.html.erb or edit.js.erb depending on the request format
end
#
# 3. The response should be some JS that, when executed, will replace part of the page or
#    something. Here's example contents for edit.html.erb:
$('#show-details').html("<%= escape_javascript render(partial: 'edit_game_details', locals: {}) %>");

# `Rails.ajax` is a wrapper for `Jquery.ajax` which handles csrf tokens and response JS execution (if request format is JS). See: https://www.rubyguides.com/2019/03/rails-ajax/



#
# ActiveRecord migrations
#

create_table :users do |t|
  t.string :name
  t.timestamps
  # ...
end

rename_table :car_users2, :car_users
drop_table :car_users

add_column :dm_requests, :needs_approval_from, :string
change_column :dm_requests, :needs_approval_from, :string, null: false
rename_column :users, :email, :email_address

add_index :dm_requests, :user_id, unique: true

execute "CREATE TABLE cars_users2 AS SELECT DISTINCT * FROM cars_users;"
