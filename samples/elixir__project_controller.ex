# This is a pretty standard CRUD controller for managing a Project resource.

defmodule RTLWeb.Manage.ProjectController do
  use RTLWeb, :controller
  alias RTL.Accounts
  alias RTL.Data

  plug :load_project when action in [:show, :edit, :update, :delete]
  plug :ensure_can_manage_project when action in [:show, :edit, :update, :delete]
  plug :ensure_superadmin when action in [:new, :create]

  def index(conn, _params) do
    projects = get_projects(conn)
    render conn, "index.html", projects: projects
  end

  def show(conn, _params) do
    project = conn.assigns.project |> RTL.Repo.preload(:admins)
    addable_admins = Accounts.get_users(not_admin_on_project: project, order: :full_name)
    prompts = Data.get_prompts(project: project, order: :id)
    count_videos = Data.count_videos(project: project)
    count_videos_coded = Data.count_videos(project: project, coded: true)

    render conn, "show.html",
      project: project,
      addable_admins: addable_admins,
      prompts: prompts,
      count_videos: count_videos,
      count_videos_coded: count_videos_coded,
      next_uncoded_video: next_uncoded_video(project)
  end

  def new(conn, _params) do
    changeset = Data.new_project_changeset()
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"project" => project_params}) do
    case Data.insert_project(project_params) do
      {:ok, project} ->
        Data.add_project_admin!(conn.assigns.current_user, project)

        conn
        |> put_flash(:info, "Project created.")
        |> redirect(to: Routes.manage_project_path(conn, :show, project))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please see errors below.")
        |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, _params) do
    changeset = Data.project_changeset(conn.assigns.project)
    render conn, "edit.html", changeset: changeset
  end

  def update(conn, %{"project" => project_params}) do
    case Data.update_project(conn.assigns.project, project_params) do
      {:ok, project} ->
        conn
        |> put_flash(:info, "Project updated.")
        |> redirect(to: Routes.manage_project_path(conn, :show, project))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please see errors below.")
        |> render("edit.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    Data.delete_project!(conn.assigns.project)

    conn
    |> put_flash(:info, "Project deleted.")
    |> redirect(to: Routes.manage_project_path(conn, :index))
  end

  #
  # Helpers
  #

  defp get_projects(conn) do
    Data.get_projects(visible_to: conn.assigns.current_user)
  end

  defp next_uncoded_video(project) do
    Data.get_video_by(
      project: project,
      coded: false,
      order: :oldest
    )
  end
end
