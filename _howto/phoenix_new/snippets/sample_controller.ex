defmodule MyAppWeb.SampleController do
  use MyAppWeb, :controller
  alias MyApp.Data.Sample

  plug :ensure_logged_in
  plug :load_sample when action in [:show, :edit, :update, :delete]

  def index(conn, _params) do
    samples = Sample.all(user: conn.assigns.current_user)
    render conn, "index.html", samples: samples
  end

  def show(conn, %{"id" => id}) do
    render conn, "show.html", org: Sample.get!(id)
  end

  def new(conn, _params) do
    changeset = Sample.new_changeset()
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"sample" => sample_params}) do
    case Sample.insert(sample_params) do
      {:ok, sample} ->
        conn
        |> put_flash(:info, "Sample created.")
        |> redirect(to: Routes.sample_path(conn, :show, sample))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please see errors below.")
        |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, _params) do
    changeset = Sample.changeset(conn.assigns.sample)
    render conn, "edit.html", changeset: changeset
  end

  def update(conn, %{"sample" => sample_params}) do
    case Sample.update(conn.assigns.sample, sample_params) do
      {:ok, sample} ->
        conn
        |> put_flash(:info, "Sample updated.")
        |> redirect(to: Routes.sample_path(conn, :show, sample))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please see errors below.")
        |> render("edit.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    Sample.delete!(conn.assigns.sample)

    conn
    |> put_flash(:info, "Sample deleted.")
    |> redirect(to: Routes.sample_path(conn, :index))
  end

  #
  # Internal
  #

  defp load_sample(conn, _) do
    sample = Sample.get!(conn.params["id"])
    assign(conn, :sample, sample)
  end
end
