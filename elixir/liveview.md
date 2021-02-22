# Phoenix LiveView tips

* On each connected mount, log that the LV is mounting and what params are received. This makes troubleshooting miles easier.

* Pay attention to how much data is sent down the wire for each action handler. You can check the websocket messages to get a sense of how much html is getting sent on each rerender.

* It's also useful to log `assigns.__changed__` on each re-render, so you can keep track of what state is getting updated each time.

* LiveComponent is very useful in optimizing state change tracking.


## References

* LiveController - a LV pattern that follows a more standard CRUD model: https://hexdocs.pm/phoenix_live_controller/Phoenix.LiveController.html

* Nice reference on how to set up Liveview JS hooks with chart.js: https://medium.com/@apboobalan/phoenix-liveview-chart-js-setup-a7459f7fee08

