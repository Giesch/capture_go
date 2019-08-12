defmodule CaptureGo.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias CaptureGo.Repo
  alias CaptureGo.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.registration_changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def change_registration(%User{} = user, attrs) do
    User.registration_changeset(user, attrs)
  end

  def authenticate_by_username_and_password(username, pw) do
    user =
      from(u in User, where: u.username == ^username)
      |> Repo.one()

    cond do
      !user -> error_not_found()
      Argon2.verify_pass(pw, user.password_hash) -> {:ok, user}
      true -> {:error, :unauthorized}
    end
  end

  defp error_not_found do
    Argon2.no_user_verify()
    {:error, :not_found}
  end
end
