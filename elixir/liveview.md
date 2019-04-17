# LiveView: tips, resources


## Resources

- https://twitter.com/chris_mccord/status/1106291353670045696
- https://github.com/phoenixframework/phoenix_live_view
- https://blog.smartlogic.io/integrating-phoenix-liveview/
- https://elixirschool.com/blog/phoenix-live-view/
- https://dennisbeatty.com/2019/03/19/how-to-create-a-counter-with-phoenix-live-view.html
- https://www.youtube.com/watch?v=2bipVjOcvdI
- https://www.youtube.com/watch?v=FfpRBh2kWCI

Example LiveView apps:

- https://github.com/chrismccord/phoenix_live_view_example
- https://github.com/zblanco/libu
- https://github.com/kerryb/liveview_demo
- http://palegoldenrod-grown-ibis.gigalixirapp.com/bear_game
- https://github.com/smeade/phoenix_live_view_example


## How to use a JS confirmation dialog with a LiveView phx-click element

LiveView listens for click events on the highest possible priority which makes it hard to override / stop propagation of click events on phx-click targets. Instead, I found it easier to make the phx-click target hidden, so that I can trigger the click event from my JS wherever I want. Here's how I did it.

In the LiveView template, I needed two targets: a visible clickable one, and a hidden one which is bound to the actual phx-click events (which must be adjacent / sibling to it in the DOM):

    <span>
      <%= link icon("trash"), to: "#", class: "text-danger", "phx-click-after-confirmation": "Are you sure you want to delete this video and its coding data?" %>
      <a href="#" class="js-hidden" phx-click="delete_video" phx-value="<%= video.id %>">the actual phx-click link</a>
    </span>

Then I wrote a standard jquery listener on the visible target that shows the confirmation message, and on confirm, emits a click event on the hidden target:

    $(document).on("click", "[phx-click-after-confirmation]", function(e){
      e.preventDefault();
      var question = $(this).attr("phx-click-after-confirmation");
      if (confirm(question)) {
        var hiddenTarget = $(this).siblings("[phx-click]")[0];
        console.log("Now triggering click on element: ", hiddenTarget);
        hiddenTarget.dispatchEvent(new Event('click'));
      }
    });
