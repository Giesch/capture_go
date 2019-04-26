defmodule CaptureGo.Games do
  @moduledoc """
  The games context.
  """

  alias CaptureGo.Accounts.User
  alias CaptureGo.Games.Game
  alias CaptureGo.Games.Lifecycle
  alias CaptureGo.Repo

  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def challenge(%Game{} = game, %User{} = challenger, password \\ nil) do
    Lifecycle.challenge(game, challenger.id, password)
    |> update_on_success()
  end

  def host_cancel(%Game{} = game, %User{} = host) do
    Lifecycle.host_cancel(game, host)
    |> update_on_success()
  end

  def move(%Game{} = game, %User{id: user_id}, point) do
    Lifecycle.move(game, user_id, point)
    |> update_on_success()
  end

  defp update_on_success(result) do
    case result do
      {:ok, changeset} -> Repo.update(changeset)
      {:error, _reason} = failure -> failure
    end
  end
end
