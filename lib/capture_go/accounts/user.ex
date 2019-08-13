defmodule CaptureGo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias CaptureGo.Games

  schema "users" do
    field :password, :string, virtual: true
    field :password_hash, :string
    field :username, :string

    has_many :hosted_games,
             Games.Game,
             foreign_key: :host_id

    has_many :challenged_games,
             Games.Game,
             foreign_key: :challenger_id

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_username()
    |> validate_password()
    |> put_password_hash()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_username()
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 1, max: 25)
    |> unique_constraint(:username)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 100)
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pw}} ->
        hashed = Argon2.hash_pwd_salt(pw)
        put_change(changeset, :password_hash, hashed)

      _ ->
        changeset
    end
  end
end
