# How to get Liveview working with Jquery Select2

See also https://www.poeticoding.com/phoenix-liveview-javascript-hooks-and-select2/.

I got this _mostly_ working and I want to capture my progress. But I got frustrated at how to trigger a Liveview form change event when the dropdown selections are changed, and gave up.


## The steps I took

  * Install select2 via npm

  * If you haven't already set up Liveview hooks, in `liveview.js` or wherever your LV socket JS is initialized, add JS hooks to the LiveSocket:
    ```js
    // Enable Phoenix LiveView
    import {Socket} from "phoenix"
    import LiveSocket from "phoenix_live_view"
    import Hooks from "./liveview_hooks"

    let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks});
    liveSocket.connect()
    ```

  * In `liveview_hooks.js`, define a hook "Select2" which will init that element as a select2 dropdown (this is generic and can be used multiple places on multiple liveviews).
    ```js
    import $ from 'jquery'
    import 'select2'

    // See https://hexdocs.pm/phoenix_live_view/0.6.0/Phoenix.LiveView.html#module-js-interop-and-client-controlled-dom
    let Hooks = {}

    Hooks.Select2 = {
      mounted() {
        initSelect2(this.el)
      },
      // Ensure the select2 is reinitialized anytime the parent form/template changes.
      // Another approach is to wrap each select2 in <div phx-update="ignore"></div>
      // to prevent updates.
      updated() {
        initSelect2(this.el)
      }
    }

    function initSelect2(element) {
      $(element).select2({width: '100%'});
    }

    // // One approach to manually triggering a LV event whenever the form is changed.
    // // This requires me to have redundant logic for serializing a form's attrs into
    // // nested key-value format (see phoenix_live_view.js serializeForm()).
    // // Plus this approach feels overly specific whereas I'd love a general solution
    // // that ensures that all select2 changes are propagated to the parent form's LV
    // // listeners same as how a plain select would work.
    //
    // Hooks.FilterForm = {
    //   mounted() {
    //     let context = this
    //     $('#filter-form').on('change', function(e){
    //       let data = $('#filter-form')
    //         .serializeArray()
    //         .reduce(function(acc, entry){ acc[entry.name] = entry.value; return acc }, {})
    //       context.pushEvent("filter_expenses", data)
    //       console.log("#filter-form change detected")
    //     })
    //   }
    // }

    export default Hooks
    ```

  * In your `.leex` template, add select2 dropdowns by adding `phx_hook: "Select2"` to any select or multiple-select element:
    ```
    <%= multiple_select f, :tag_ids, Enum.map(@tags, & {&1.name, &1.id}), selected: get_change(@new_changeset, :tag_ids), phx_hook: "Select2" %>
    ```

  * Now start the dev server and load the page and those select2 elements should be rendered correctly. You can select items from them, and on form/template re-render the select2 element won't get destroyed (thanks to binding the init logic to both mounted() and updated() above), and when you submit the parent form, the selections will be included in the submitted attrs.

  * What's NOT yet working (and I gave up on for now) is, whenever a select2 selection changes, the parent form's phx_change listener should be triggered same as it would if you changed the selection in a bare select or input. I'd like to find a general solution to that. Notes so far:

    - I suspect there's a way to dispatch a CustomEvent to the parent form to trick the Liveview listener into executing its normal "Oh, something changed" logic.

    - The same problem comes up if you use JS to set the value of a form's text field, and then you want to force the form's liveview phx_change listener to realize that a change happened. That might be a simpler case to test/troubleshoot with.

    - Check phoenix_live_view.js for uses of the `PHX_CHANGE` constant, since that's the name of the listener applied to the form.

    - phoenix_live_view.js bindForms() defines the listeners for form change & submit. I just need to figure out how to fake those.

    - Plan B is to use the Hooks system to manually pushEvent whenever the select2 changes. But that requires adding redundant (and nontrivial) logic for serializing the form data into nested object format. See my commented-out section in the hooks file above.
