defmodule CaptureGo.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  import CaptureGo.ColorUtils
  alias CaptureGo.Accounts
  alias CaptureGo.Games.Enums
  alias CaptureGo.Games.Game
  alias CaptureGo.Goban

  schema "games" do
    field :name, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :host_color, Enums.Color, default: :white
    field :state, Enums.LifecycleState, default: :open
    field :goban, Goban, default: Goban.new()

    belongs_to :host,
               Accounts.User,
               foreign_key: :host_id

    belongs_to :challenger,
               Accounts.User,
               foreign_key: :challenger_id

    timestamps()
  end

  def participant?(%Game{} = game, user_id) do
    user_id && (user_id == game.host_id || user_id == game.challenger_id)
  end

  def player_color(%Game{host_color: host_color} = game, user_id) do
    cond do
      game.host_id == user_id -> {:ok, host_color}
      game.challenger_id == user_id -> {:ok, opposite_color(host_color)}
      true -> {:error, :not_participant}
    end
  end

  @allowed_fields [
    :name,
    :host_color,
    :state,
    :host_id,
    :password,
    :challenger_id,
    :goban
  ]

  @doc false
  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, @allowed_fields)
    |> validate_game()
    |> put_password_hash()
  end

  @new_game_allowed_fields [
    :name,
    :host_color,
    :host_id,
    :password,
    :goban
  ]

  def new_game_changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, @new_game_allowed_fields)
    |> validate_game()
    |> put_password_hash()
  end

  @required_fields [
    :name,
    :host_color,
    :state,
    :host_id
  ]

  defp validate_game(game) do
    game
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:host_id)
    |> foreign_key_constraint(:challenger_id)
  end

  def put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pw}} ->
        hashed = Argon2.hash_pwd_salt(pw)
        put_change(changeset, :password_hash, hashed)

      _ ->
        changeset
    end
  end
end
