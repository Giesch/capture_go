defmodule CaptureGo.GameRecord.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias CaptureGo.Accounts
  alias CaptureGo.GameRecord.Enums

  schema "games" do
    field :name, :string
    field :password, :string
    field :host_color, Enums.Color
    field :lifecycle_state, Enums.LifecycleState

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
    :challenger_id
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
