# One-line full request logging inspired by Plug.Logger.
# See https://github.com/elixir-plug/plug/blob/v1.8.0/lib/plug/logger.ex
# Need to restart the server after updating this file.
defmodule MyAppWeb.RequestLogger do
  require Logger

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    start_time = System.monotonic_time()

    Plug.Conn.register_before_send(conn, fn(conn) ->
      Logger.log(:info, fn ->
        # We don't want passwords etc. being logged
        params = inspect(Phoenix.Logger.filter_values(conn.params))
        # Clean up GraphQL query params for easier readability
        params = Regex.replace(~r/\\n/, params, " ")
        params = Regex.replace(~r/ +/, params, " ")

        ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

        # Log any important session data eg. logged-in user
        user = conn.assigns[:current_user]
        user_string = if user, do: "#{user.id} (#{user.name})", else: "(none)"

        # Note redirect, if any
        redirect = Plug.Conn.get_resp_header(conn, "location")
        redirect_string = if redirect != [], do: " redirected_to=#{redirect}", else: ""

        # Calculate time taken (always in ms for consistency
        stop_time = System.monotonic_time()
        time_us = System.convert_time_unit(stop_time - start_time, :native, :microsecond)
        time_ms = div(time_us, 100) / 10

        "■ method=#{conn.method} path=#{conn.request_path} params=#{params} "<>
        "ip=#{ip} user=#{user_string} "<>
        "status=#{conn.status}#{redirect_string} duration=#{time_ms}ms"
      end)

      conn
    end)
  end
end
