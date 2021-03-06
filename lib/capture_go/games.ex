defmodule CaptureGo.Games do
  @moduledoc """
  The games context.
  """

  import Ecto.Query, warn: false

  alias CaptureGo.Accounts.User
  alias CaptureGo.Games.{Game, Lifecycle}
  alias CaptureGo.Repo
  alias CaptureGoWeb.{LiveGame, LiveLobby}

  def get_game!(id) do
    Game
    |> Repo.get!(id)
    |> Repo.preload([:host, :challenger])
  end

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
      preload: [:host, :challenger]
  end

  def challenge(game_or_game_id, challenger, password \\ nil)

  def challenge(%Game{} = game, %User{} = challenger, password) do
    do_challenge(game, challenger.id, password)
  end

  def challenge(game_id, %User{} = challenger, password)
      when is_integer(game_id) do
    case Repo.get(Game, game_id) do
      nil -> {:error, :no_game}
      game -> do_challenge(game, challenger.id, password)
    end
  end

  defp do_challenge(%Game{} = game, challenger_id, password) do
    Lifecycle.challenge(game, challenger_id, password)
    |> update_on_success()
    |> call_on_success(&LiveLobby.broadcast_started_game(&1))
  end

  def host_cancel(%Game{} = game, %User{} = host) do
    Lifecycle.host_cancel(game, host)
    |> update_on_success()
    |> call_on_success(&LiveLobby.broadcast_ended_game(&1))
  end

  def move(%Game{id: game_id}, %User{id: user_id}, point) do
    game = get_game!(game_id)
    do_move(game, user_id, point)
  end

  def move(game_id, %User{id: user_id}, point) do
    game = get_game!(game_id)
    do_move(game, user_id, point)
  end

  defp do_move(%Game{} = game, user_id, point) do
    Lifecycle.move(game, user_id, point)
    |> update_on_success()
    |> call_on_success(&broadcast_move/1)
  end

  def pass(%Game{} = game, %User{} = user) do
    Lifecycle.pass(game, user)
    |> update_on_success()
    |> call_on_success(&broadcast_move/1)
  end

  def resign(%Game{} = game, %User{id: user_id}) do
    Lifecycle.resign(game, user_id)
    |> update_on_success()
    |> call_on_success(&broadcast_move/1)
  end

  defp broadcast_move(%Game{state: state} = game) do
    LiveGame.broadcast_game_change(game)

    if state == :over do
      LiveLobby.broadcast_ended_game(game)
    end
  end

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
