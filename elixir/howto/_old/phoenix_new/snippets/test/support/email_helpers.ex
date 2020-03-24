defmodule MyAppWeb.EmailHelpers do
  use ExUnit.CaseTemplate

  def count_emails_sent, do: length(Bamboo.SentEmail.all())

  def assert_email_sent([to: to, subject: subject]) do
    to = [to] |> List.flatten() |> Enum.sort()

    matches = Bamboo.SentEmail.all()
    matches = Enum.filter(matches, & &1.to |> Keyword.values() |> Enum.sort() == to)
    matches = Enum.filter(matches, & &1.subject =~ subject)

    if length(matches) == 0 do
      all = Enum.map(Bamboo.SentEmail.all(), fn email ->
        to = email.to |> Keyword.values() |> Enum.sort()
        "  * [to: #{inspect(to)}, subject: \"#{email.subject}\"]"
      end)

      raise "No matching email found.\n\nSearched for:\n    [to: #{to}, subject: \"#{subject}\"]\n\nAll emails sent:\n#{Enum.join(all, "\n")}"
    end
  end
end
