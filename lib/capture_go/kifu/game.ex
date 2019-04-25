defmodule CaptureGo.Kifu.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias CaptureGo.Accounts
  alias CaptureGo.Kifu.Enums

  schema "games" do
    field :name, :string
    field :password, :string
    field :host_color, Enums.Color

    belongs_to :host,
               Accounts.User,
               foreign_key: :host_id

    belongs_to :challenger,
               Accounts.User,
               foreign_key: :challenger_id

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :password])
    |> validate_required([:name])
  end
end
