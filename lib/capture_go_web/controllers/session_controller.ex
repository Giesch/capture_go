defmodule CaptureGoWeb.SessionController do
  use CaptureGoWeb, :controller

  import CaptureGoWeb.LiveRedirect, only: [lobby_redirect: 1]
  alias CaptureGoWeb.Auth

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"email" => email, "password" => pw}}) do
    case Auth.login_by_email_and_pass(conn, email, pw) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> lobby_redirect()

      {:error, conn} ->
        conn
        |> put_flash(:error, "Invalid email/password combination")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Auth.logout()
    |> lobby_redirect()
  end
end
