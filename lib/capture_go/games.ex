defmodule CaptureGo.Games do
  @moduledoc """
  The games context.
  """

  import Ecto.Query, warn: false

  alias CaptureGo.Accounts.User
  alias CaptureGo.Games.Game
  alias CaptureGo.Games.Lifecycle
  alias CaptureGo.Repo
  alias CaptureGoWeb.LiveLobby

  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.new_game_changeset(attrs)
    |> Repo.insert()
    |> preload_players()
    |> call_on_success(&LiveLobby.broadcast_new_game(&1))
  end

  def lobby(opts \\ []) do
    size = Keyword.get(opts, :size, 10)
    Repo.transaction(fn -> lobby_games(size) end)
  end

  defp lobby_games(size) do
    open_games = open_games(size) |> Repo.all()
    active_games = active_games(size) |> Repo.all()
    %{open_games: open_games, active_games: active_games}
  end

  defp open_games(size) do
    from g in Game,
      where: g.state == ^:open,
      order_by: g.inserted_at,
      limit: ^size,
      preload: :host
  end

  defp active_games(size) do
    from g in Game,
      where: g.state == ^:started,
      order_by: g.updated_at,
      limit: ^size,
      preload: :host
  end

  def challenge(%Game{} = game, %User{} = challenger, password \\ nil) do
    Lifecycle.challenge(game, challenger.id, password)
    |> update_on_success()
    |> call_on_success(&LiveLobby.broadcast_started_game(&1))
  end

  def host_cancel(%Game{} = game, %User{} = host) do
    Lifecycle.host_cancel(game, host)
    |> update_on_success()
    |> call_on_success(&LiveLobby.broadcast_ended_game(&1))
  end

  def move(%Game{} = game, %User{id: user_id}, point) do
    Lifecycle.move(game, user_id, point)
    |> update_on_success()
    |> call_on_success(&broadcast_if_game_over(&1))
  end

  defp broadcast_if_game_over(%Game{state: :over} = game) do
    LiveLobby.broadcast_ended_game(game)
  end

  defp broadcast_if_game_over(_game), do: nil

  defp update_on_success(result) do
    case result do
      {:ok, changeset} -> Repo.update(changeset) |> preload_players()
      {:error, _reason} = failure -> failure
    end
  end

  defp call_on_success({:ok, game} = result, on_success)
       when is_function(on_success, 1) do
    on_success.(game)
    result
  end

  defp call_on_success(result, _on_success) do
    result
  end

  defp preload_players({:ok, game}) do
    {:ok, Repo.preload(game, [:host, :challenger])}
  end

  defp preload_players(result) do
    result
  end
end