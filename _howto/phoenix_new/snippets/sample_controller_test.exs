defmodule MyAppWeb.SampleControllerTest do
  use MyAppWeb.ConnCase, async: true
  alias MyApp.Data.Sample

  describe "plugs" do
    test "all actions reject if no user is logged in", %{conn: conn} do
      conn = get(conn, Routes.sample_path(conn, :index))
      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert conn.halted
    end
  end

  describe "#index" do
    test "lists all my samples (but not others')", %{conn: conn} do
      {conn, user} = login_as_new_user(conn)
      sample1 = Factory.insert_sample(user_id: user.id)
      sample2 = Factory.insert_sample(user_id: user.id)
      sample3 = Factory.insert_sample()

      conn = get(conn, Routes.sample_path(conn, :index))

      assert conn.resp_body =~ "test-page-sample-index"
      assert conn.resp_body =~ sample1.name
      assert conn.resp_body =~ sample2.name
      assert !(conn.resp_body =~ sample3.name)
    end
  end

  describe "#show" do
    test "renders correctly", %{conn: conn} do
      {conn, user} = login_as_new_user(conn)
      sample = Factory.insert_sample(user_id: user.id)

      conn = get(conn, Routes.sample_path(conn, :show, sample))

      assert conn.resp_body =~ "test-page-sample-show-#{sample.id}"
    end

    test "404 if I'm not the sample owner", %{conn: conn} do
      {conn, user} = login_as_new_user(conn)
      sample = Factory.insert_sample()

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, Routes.sample_path(conn, :show, sample))
      end
    end
  end

  describe "#new" do
    test "renders correctly", %{conn: conn} do
      {conn, _} = login_as_new_user(conn)

      conn = get(conn, Routes.sample_path(conn, :new))

      assert conn.resp_body =~ "test-page-sample-new"
    end
  end

  describe "#create" do
    test "inserts the sample and redirects to the list", %{conn: conn} do
      {conn, user} = login_as_new_user(conn)

      params = %{"sample" => %{"name" => "Office back wall", "cm_from_screen" => 150}}
      conn = post(conn, Routes.sample_path(conn, :create), params)

      sample = Sample.first(user: user)
      assert sample != nil
      assert sample.name == "Office back wall"
      assert redirected_to(conn) == Routes.sample_path(conn, :index)
    end

    test "rejects changes if invalid", %{conn: conn} do
      {conn, _user} = login_as_new_user(conn)
      old_count = Sample.count()

      params = %{"sample" => %{"name" => " ", "cm_from_screen" => 150}}
      conn = post(conn, Routes.sample_path(conn, :create), params)

      assert Sample.count() == old_count
      assert html_response(conn, 200) =~ "name can't be blank"
    end
  end

  describe "#edit" do
    test "renders correctly", %{conn: conn} do
      {conn, user} = login_as_new_user(conn)
      sample = Factory.insert_sample(user_id: user.id)

      conn = get(conn, Routes.sample_path(conn, :edit, sample))

      assert conn.resp_body =~ "test-page-sample-edit-#{sample.id}"
    end

    test "rejects if not sample owner", %{conn: conn} do
      {conn, _user} = login_as_new_user(conn)
      sample = Factory.insert_sample()

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, Routes.sample_path(conn, :edit, sample))
      end
    end
  end

  describe "#update" do
    test "saves changes and redirects", %{conn: conn} do
      {conn, user} = login_as_new_user(conn)
      sample = Factory.insert_sample(user_id: user.id)

      params = %{"sample" => %{"name" => "New name"}}
      conn = patch(conn, Routes.sample_path(conn, :update, sample), params)

      assert Sample.get!(sample.id).name == "New name"
      assert redirected_to(conn) == Routes.sample_path(conn, :index)
    end

    test "rejects changes if invalid", %{conn: conn} do
      {conn, user} = login_as_new_user(conn)
      sample = Factory.insert_sample(user_id: user.id)

      params = %{"sample" => %{"name" => " "}}
      conn = patch(conn, Routes.sample_path(conn, :update, sample), params)

      assert Sample.get!(sample.id).name == sample.name
      assert html_response(conn, 200) =~ "name can't be blank"
    end

    test "404 if not sample owner", %{conn: conn} do
      {conn, _user} = login_as_new_user(conn)
      sample = Factory.insert_sample()
      params = %{"sample" => %{"name" => "New name"}}

      assert_raise Ecto.NoResultsError, fn ->
        patch(conn, Routes.sample_path(conn, :update, sample), params)
      end
    end
  end

  describe "#delete" do
    test "deletes the sample", %{conn: conn} do
      {conn, user} = login_as_new_user(conn)
      sample = Factory.insert_sample(user_id: user.id)

      conn = delete(conn, Routes.sample_path(conn, :delete, sample))

      assert Sample.count(id: sample.id) == 0
      assert redirected_to(conn) == Routes.sample_path(conn, :index)
    end

    test "404 if not sample owner", %{conn: conn} do
      {conn, _user} = login_as_new_user(conn)
      sample = Factory.insert_sample()

      assert_raise Ecto.NoResultsError, fn ->
        delete(conn, Routes.sample_path(conn, :delete, sample))
      end

      assert Sample.count(id: sample.id) == 1
    end
  end
end
