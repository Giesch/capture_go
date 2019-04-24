defmodule CaptureGoWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3]
  import CaptureGoWeb.LiveRedirect, only: [lobby_redirect: 1]
  alias CaptureGo.Accounts

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    user = conn.assigns[:current_user] || get_current_user(conn)

    if user do
      put_current_user(conn, user)
    else
      assign(conn, :current_user, nil)
    end
  end

  defp get_current_user(conn) do
    user_id = get_session(conn, :user_id)
    user_id && Accounts.get_user(user_id)
  end

  def login_by_email_and_pass(conn, email, given_pass) do
    case Accounts.authenticate_by_email_and_password(email, given_pass) do
      {:ok, user} -> {:ok, login(conn, user)}
      {:error, _reason} -> {:error, conn}
    end
  end

  def login(conn, user) do
    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  def require_login(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> lobby_redirect()
      |> halt()
    end
  end

  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end
end
