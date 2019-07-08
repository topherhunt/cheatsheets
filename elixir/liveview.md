# LiveView: tips, resources


## Resources

- https://twitter.com/chris_mccord/status/1106291353670045696
- https://github.com/phoenixframework/phoenix_live_view
- https://blog.smartlogic.io/integrating-phoenix-liveview/
- https://elixirschool.com/blog/phoenix-live-view/
- https://dennisbeatty.com/2019/03/19/how-to-create-a-counter-with-phoenix-live-view.html
- https://www.youtube.com/watch?v=2bipVjOcvdI
- https://www.youtube.com/watch?v=FfpRBh2kWCI
- Debounce: https://dev.to/tizpuppi/phoenix-live-view-debounce-4icf

Example LiveView apps:

- https://github.com/chrismccord/phoenix_live_view_example
- https://github.com/zblanco/libu
- https://github.com/kerryb/liveview_demo
- http://palegoldenrod-grown-ibis.gigalixirapp.com/bear_game
- https://github.com/smeade/phoenix_live_view_example


## Tips

  * LiveView pubsub broadcasts should include the changed object so receivers don't each have to re-fetch the same record.

  * Don't do LiveView partials on static pages. If I need LV on a page, make the whole page the LV.

  * If you're rendering a video inside a LV, watch out for CPU spikes, especially if the LV will rerender frequently. Chrome doesn't seem to like this.
