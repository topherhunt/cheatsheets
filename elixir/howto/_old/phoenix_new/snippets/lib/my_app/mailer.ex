defmodule MyApp.Mailer do
  use Bamboo.Mailer, otp_app: :my_app
  require Logger

  def send(email) do
    try do
      deliver_now(email)
      {:ok}
    # SMTP failures may raise ErlangErrors which need to be caught rather than rescued (?)
    catch e ->
      Logger.warn "Error sending email #{inspect(email.subject)} to #{inspect(email.to)}: #{inspect(e)}"
      {:error, e}
    end
  end
end
