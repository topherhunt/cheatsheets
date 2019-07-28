defmodule MyAppWeb.IntegrationHelpers do
  use ExUnit.CaseTemplate
  # See https://github.com/HashNuke/hound for docs
  use Hound.Helpers
  alias MyApp.Factory
  alias MyAppWeb.Router.Helpers, as: Routes

  #
  # High-level
  #

  def login_as_new_user(conn, params \\ %{}) do
    user = Factory.insert_user(params)
    navigate_to Routes.auth_path(conn, :force_login, user.uuid)
    user
  end

  def login_as_superadmin(conn) do
    login_as_new_user(conn, %{email: "superadmin@example.com"})
  end

  #
  # DOM
  #

  # I always use css selectors, so I can simplify the helpers a bit
  def find_element(selector), do: find_element(:css, selector)

  def find_all_elements(selector), do: find_all_elements(:css, selector)

  def find_within_element(el, selector), do: find_within_element(el, :css, selector)

  def assert_text(text) do
    assert visible_page_text() =~ text
  end

  def assert_selector(sel, opts \\ %{}) do
    actual = count_selector(sel)

    if count = opts[:count] do
      assert actual == count,
             "Expected to find \"#{sel}\" #{count} times, but found it #{actual} times."
    else
      assert actual >= 1, "Expected to find \"#{sel}\" 1+ times, but found it 0 times."
    end
  end

  def refute_selector(sel) do
    actual = count_selector(sel)
    assert actual == 0, "Expected NOT to find selector \"#{sel}\", but found #{actual}."
  end

  def count_selector(selector) do
    length(find_all_elements(selector))
  end

  # Usage:
  # > wait_until(fn -> count_selector(".something") > 0 end)
  def wait_until(func, failures \\ 0) do
    cond do
      func.() == true ->
        nil

      failures < 10 ->
        Process.sleep(100)
        wait_until(func, failures + 1)

      true ->
        assert false, "Waited 1 sec, but the expected condition never became true."
    end
  end

  #
  # Debugging
  #

  def print_page_source() do
    IO.puts("<<<<<<< Page source: >>>>>>")
    IO.puts(page_source())
    IO.puts("<<<<<<<<<<<<<<>>>>>>>>>>>>>")
  end
end
