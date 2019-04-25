defmodule CaptureGo.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias CaptureGo.Accounts
  alias CaptureGo.Games.Enums
  alias CaptureGo.Goban

  schema "games" do
    field :name, :string
    field :password, :string
    field :host_color, Enums.Color, default: :white
    field :lifecycle_state, Enums.LifecycleState, default: :open
    field :goban, Goban, default: Goban.new()

    belongs_to :host,
               Accounts.User,
               foreign_key: :host_id

    belongs_to :challenger,
               Accounts.User,
               foreign_key: :challenger_id

    timestamps()
  end

  @allowed_fields [
    :name,
    :host_color,
    :lifecycle_state,
    :host_id,
    :password,
    :challenger_id,
    :goban
  ]

  @required_fields [
    :name,
    :host_color,
    :lifecycle_state,
    :host_id
  ]

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:host_id)
    |> foreign_key_constraint(:challenger_id)
  end
end
