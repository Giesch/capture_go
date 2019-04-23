defmodule CaptureGoWeb.UserController do
  use CaptureGoWeb, :controller

  alias CaptureGo.Accounts
  alias CaptureGo.Accounts.User
  alias CaptureGoWeb.Auth
  import CaptureGoWeb.LiveRedirect, only: [lobby_redirect: 1]

  def new(conn, _params) do
    changeset = Accounts.change_registration(%User{}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> Auth.login(user)
        |> put_flash(:info, "#{user.username} created!")
        |> lobby_redirect()

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
