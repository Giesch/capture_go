defmodule CaptureGo.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias CaptureGo.Accounts.User

  schema "games" do
    field :name, :string
    field :password, :string

    belongs_to :host, User, foreign_key: :host_id
    belongs_to :challenger, User, foreign_key: :challenger_id

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :password])
    |> validate_required([:name])
  end
end
