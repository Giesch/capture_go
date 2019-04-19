defmodule CaptureGoWeb.AuthTest do
  use CaptureGoWeb.ConnCase

  import CaptureGo.TestHelpers
  alias CaptureGoWeb.Auth
  alias CaptureGo.Accounts.User

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(CaptureGoWeb.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "require_login halts when no current_user exists", %{conn: conn} do
    conn = Auth.require_login(conn, [])
    assert conn.halted
  end

  test "require_login continues when current_user exists", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %User{})
      |> Auth.require_login([])

    refute conn.halted
  end

  test "login puts the user in the session", %{conn: conn} do
    login_conn =
      conn
      |> Auth.login(%User{id: 123})
      |> send_resp(:ok, "")

    next_conn = get(login_conn, "/")
    assert get_session(next_conn, :user_id) == 123
  end

  test "logout drops the session", %{conn: conn} do
    logout_conn =
      conn
      |> put_session(:user_id, 123)
      |> Auth.logout()
      |> send_resp(:ok, "")

    next_conn = get(logout_conn, "/")
    refute get_session(next_conn, :user_id)
  end

  test "Auth.call places user from session into assigns", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> put_session(:user_id, user.id)
      |> Auth.call(Auth.init([]))

    assert conn.assigns.current_user.id == user.id
  end

  test "call with no session sets current_user assign to nil", %{conn: conn} do
    conn = Auth.call(conn, Auth.init([]))
    assert conn.assigns.current_user == nil
  end

  test "login with a valid username and password", %{conn: conn} do
    user = user_fixture(username: "me", email: "me@test", password: "secret")
    {:ok, conn} = Auth.login_by_email_and_pass(conn, "me@test", "secret")
    assert conn.assigns.current_user.id == user.id
  end

  test "login with a not found user", %{conn: conn} do
    result = Auth.login_by_email_and_pass(conn, "me@test", "secret")
    assert {:error, ^conn} = result
  end

  test "login with password mismatch", %{conn: conn} do
    _user = user_fixture(username: "me", email: "me@test", password: "secret")
    result = Auth.login_by_email_and_pass(conn, "me@test", "whoops")
    assert {:error, ^conn} = result
  end
end
