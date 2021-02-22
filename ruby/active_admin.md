# ActiveAdmin

- Basic usage: https://activeadmin.info/documentation.html

- How to show a custom text block on a resource index page: see Delphi app/admin/coupons.rb:95

- How to add custom filters/scopes to a resource index page: see Delphi event.rb ransackable_scopes


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
        f.input :aasm_state, label: "State", as: :select, collection: Game.aasm.states.map(&:name), include_blank: false

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
