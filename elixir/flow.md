# Stream, Flow, Task.async_stream, and other concurrency stuff

Here's an exercise I did showing a few ways of processing a pipe (list) of items:

```rb
test "basic Flow test" do
  # The naive workflow: an Enum.map pipeline.
  # Items are eagerly loaded into memory and processed in sequence. No concurrency.
  (1..20)
  |> Enum.map(& "#{&1}")
  |> Enum.map(fn i -> Process.sleep(:rand.uniform(1000)); IO.inspect(i) end)
  |> IO.inspect()

  # Here we use Stream which lets us process one item at a time rather than loading the
  # entire dataset into memory at each step (ie. lazy processing).
  # Friendlier on memory usage, but no benefit for concurrency.
  (1..20)
  |> Stream.map(& "#{&1}")
  |> Stream.map(fn i -> Process.sleep(:rand.uniform(1000)); IO.inspect(i) end)
  |> Enum.to_list()
  |> IO.inspect()

  # This is the same pipe, but using Flow for concurrency.
  # You can set the # of stages when initializing the Flow and each time you partition.
  # (Stages = # concurrent "workers" and defaults to your machine's # cores.)
  (1..100)
  |> Flow.from_enumerable(max_demand: 1, stages: 25)
  |> Flow.map(& "#{&1}")
  |> Flow.map(fn i -> Process.sleep(1000); IO.inspect(i) end)
  |> Enum.to_list()
  |> IO.inspect()

  # Here we use Task.async_stream which also concurrently processes a stream of data.
  # I like this. It's conceptually simpler than Flow, but not as powerful/flexible.
  # Set max_concurrency to override the # of processes which defaults to # cores.
  (1..100)
  |> Task.async_stream(fn i -> Process.sleep(1000); IO.inspect(i) end, max_concurrency: 25)
  |> Enum.to_list()
  |> IO.inspect()

  # Testing a large number of concurrent processes using Task.async. OTP can
  # handle millions of processes.
  (1..1_000_000)
  |> Enum.map(&
    Task.async(fn ->
      IO.puts "Processing #{&1}..."
      Process.sleep(:rand.uniform(1000))
      IO.puts "Done with #{&1}"
    end)
  )
end
```
