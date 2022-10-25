# ActiveAdmin

- Basic usage: https://activeadmin.info/documentation.html

- How to add custom filters/scopes to a resource index page: see Delphi event.rb ransackable_scopes


## Custom index list

Here's an example of customizing the index list, with custom action links.

    index do
      selectable_column
      id_column
      column :user do |attendee|
        link_to attendee.user.username, admin_user_path(attendee.user)
      end
      column :game
      column :paid
      column :game_role
      column :updated_at

      # Using :sortable option, you can manually set both the column header and the value 
      # expression, independently of the field used for sorting.
      column("AWC", sortable: :avg_word_count) { |a| a.avg_word_count }

      actions(defaults: false) do |a|
        links = ""
        links << link_to("View", admin_attendee_path(a), class: "member_link")
        links << link_to("Edit", edit_admin_attendee_path(a), class: "member_link")
        links << link_to("Delete", admin_attendee_path(a), method: :delete, class: "member_link", "data-confirm": "Really delete this attendee? Any paid game fees will be refunded.")
        links.html_safe
      end
    end

Add a custom text block to the index page:

    sidebar "Instructions", only: :index do
      "<div>Here's some important instructions</div>".html_safe
    end

How to add a custom filter/scope to a resource index page:
(thanks to Delphi event.rb #can_upload_images)

  - In the model, define the scope with a parameter:
    ```rb
    scope :is_happy, ->(value) do
      if value == 'Yes'
        where(happy: true)
      else
        where(happy: false)
      end
    end
    ```

  - In the model, specify which scopes should be exposed as Ransack filters:
    ```rb
    def self.ransackable_scopes(auth_object = nil)
      [:is_happy] # this adds to the default list of available Ransack filters
    end
    ```

  - In the AA resource file, define the filter:
    ```rb
    filter :is_happy, as: :select, collection: ["Yes", "No"]
    ```


## Custom new/edit/delete buttons

To customize a resource's new/edit/delete buttons, clear all action items and then re-add:

```
    config.clear_action_items!

    action_item :new, only: :index do
      link_to "New", new_resource_path
    end

    action_item :edit, only: :show do
      link_to "Edit", edit_resource_path
    end

    action_item :destroy, only: :show do
      link_to "Delete", resource_path, method: :delete, "data-confirm": "Really delete this attendee? Any paid game fees will be refunded."
    end
```


## Filters

Here's some example filters.
Dynamic collections for filters (eg. from DB records) should be wrapped in a lambda.

    filter :name
    filter :date
    filter :creator, collection: -> { User.all.map { |u| [u.username, u.id] } }
    filter :aasm_state, label: "State", as: :select, collection: %w(pending confirmed completed closed canceled)

Or disable filters for this resource:

    config.filters = false


## Forms

Here's an example custom form with some complex elements.
Dynamic collections for forms don't need to be wrapped in a lambda.
Note the explanation div and ul added in the middle.

    form do |f|
      f.inputs do
        f.input :name
        f.input :cost, label: "Cost (GP)"
        f.input :creator, collection: User.all.map { |u| [u.username, u.id] }
        f.input :aasm_state, label: "State", as: :select,
          collection: Game.aasm.states.map(&:name), include_blank: false,
          hint: "This hint text will appear in gray italics below the input field."

        div { "<strong>WARNING: Manually changing the game's state can cause important events to be skipped or repeated.</strong> <br>Make sure you know what you're doing! Here's some tips on the effects of different states:".html_safe }
        ul(class: "bulleted-list") do
          li { "'pending' => once the game date has passed, the game will be auto cancelled if it hasn't been confirmed by then." }
          li { "'confirmed' => once the game date has passed, we'll send out 'DM review due' and 'DM payout is pending' notifications, and mark the game 'completed'."}
          li { "'completed' => if relevant, we'll send a payout to the DM, then mark the game 'closed'." }
          li { "'closed' => no payout will be sent, even if a payout is overdue." }
        end
      end
      f.actions
    end


## Show

Here's a custom show page with a section to list children resources.
Don't forget the `active_admin_comments` at the end.

    show do
      attributes_table do
        row(:creator) { link_to campaign.creator.username, campaign.creator }
        row :name
        row :first_game
        row :is_ended
        row :created_at
        row :updated_at
      end

      panel "Games" do
        table do
          tr do
            th { "ID" }
            th { "Name" }
            th { "Date" }
          end
          campaign.games.order(:created_at).each do |game|
            tr do
              td { game.id  }
              td { link_to game.name, admin_game_path(game) }
              td { game.date }
            end
          end
        end
      end

      div do
        text_node "One piece of text"
        text_node "Anothe piece of text"
      end

      active_admin_comments
    end
