# Testing Elixir apps


## Hound integration tests

Checklist for troubleshooting integration test errors:

  * "Invalid session id" error may mean that your Chromedriver version doesn't match your Chrome major version. Double-check `chromedriver --version` versus Chrome's installed version.

  * Can you repro the failure in a live Chrome browser? If so, troubleshoot it there.

  * Changed any JS lately? Make sure the server is running so Webpack can rebuild!

  * Can you spot what's wrong by looking at a page screenshot / source / JS logs?

    ```rb
    take_screenshot()
    IO.puts "JS logs: \n<<<<\n#{fetch_log()}\n>>>>\n\n"<>
            "HTML source:\n<<<<\n#{page_source()}\n>>>>"
    ```

  * Is this a timing issue? Add `Process.sleep(1000)` before the failing assertion.

  * Use non-headless ChromeDriver so you can see what Hound sees:
    (then add `Proces.sleep(5000)` as relevant to pause execution)

    ```rb
    config :hound, driver: "chrome_driver" #, browser: "chrome_headless"
    ```


## Pattern for stubbing external http requests (api calls etc.)

```rb
# A support module defines the helper:
defmodule Cerberus.MockHelpers do
  defmacro with_stubbed_requests(stubs, do: block) do
    quote do
      with_mock(HTTPoison, [
        get: fn url, _headers, _opts -> HTTPoison.get(url) end,
        get: fn url, _headers -> HTTPoison.get(url) end,
        get: fn url ->
          url = stringify_url(url)
          {method, path, response} = find_matching_stub(:get, url, unquote(stubs))
          status = response[:status] || 200
          headers = response[:headers] || []
          body = response[:body] || raise("No response body for stub of #{method} #{path}")
          {:ok, %{status_code: status, headers: headers, body: body}}
        end
      ]) do
        unquote(block)
      end
    end
  end

  def stringify_url(%URI{} = uri), do: URI.to_string(uri)
  def stringify_url(url), do: url

  def find_matching_stub(method, url, stubs) do
    Enum.find(stubs, fn({stub_method, stub_partial_url, _}) ->
      stub_method == method && String.contains?(url, stub_partial_url)
    end)
    || raise("Unstubbed http request to #{method} #{url}")
  end
end

# ...
# Then you wrap your test in a `with_stubbed_requests` call specifying a list of stubs:
test "overall import runs correctly" do
  with_stubbed_requests [
    {:get, "/event/44530?", stub_event_response()},
    {:get, "/event/44530/entry?", stub_entries_response()},
    {:get, "/entry/400001/results?", stub_entry1_results_response()},
    {:get, "/entry/400002/results?", stub_entry2_results_response()},
    {:get, "/entry/400003/results?", stub_entry3_results_response()},
  ] do
    event = Factory.insert_event(chronotrack_event_id: 44530)

    ImportEvent.call(event.chronotrack_event_id)

    # Entries were created; results and rankings were filled in correctly
    entry1 = Repo.get_by!(Cerberus.Entry, chronotrack_entry_id: 400001)
    entry2 = Repo.get_by!(Cerberus.Entry, chronotrack_entry_id: 400002)
    entry3 = Repo.get_by!(Cerberus.Entry, chronotrack_entry_id: 400003)
    assert %{completion_time: 1548.16, overall_rank: 1, gender_rank: 1} = entry1
    assert %{completion_time: 2176.9, overall_rank: 3, gender_rank: 2} = entry2
    assert %{completion_time: 2105.07, overall_rank: 2, gender_rank: 1} = entry3
  end
end
```
