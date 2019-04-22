defmodule CaptureGo.LobbyServer do
  use GenServer

  alias CaptureGo.Lobby
  alias CaptureGo.GameSupervisor
  alias CaptureGo.GameServer
  alias CaptureGo.LobbyEvents
  alias CaptureGo.LobbyGame

  # TODO
  # clean lobby - background job
  #   remove inactive tables (as defined by model)
  #   remove invalid/dead game pids
  #   UI for when your game got killed: dump into lobby with error message?

  def start_link(_) do
    GenServer.start_link(__MODULE__, Lobby.new(), name: __MODULE__)
  end

  # TODO do these do anything useful?
  # integration tests should use broadcasted message,
  # unit tests should use the actual state
  def open_games() do
    GenServer.call(__MODULE__, :open_games)
  end

  def active_games() do
    GenServer.call(__MODULE__, :active_games)
  end

  def open_game(%LobbyGame{} = game, host_token, password \\ nil) do
    request = game_state_request(game.id, host_token, password)
    GenServer.call(__MODULE__, {:open_game, {request, game}})
  end

  def begin_game(game_id, challenger_token, password \\ nil) do
    request = game_state_request(game_id, challenger_token, password)
    GenServer.call(__MODULE__, {:begin_game, request})
  end

  def host_cancel(game_id, host_token) do
    request = game_state_request(game_id, host_token)
    GenServer.call(__MODULE__, {:host_cancel, request})
  end

  def end_game(game_id) do
    GenServer.call(__MODULE__, {:end_game, game_id})
  end

  # TODO something better than this; a submodule struct or whatever
  # also, if open game is just different then make it just different
  defp game_state_request(game_id, player_token, password \\ nil) do
    %{game_id: game_id, token: player_token, password: password}
  end

  ###################################################

  @impl GenServer
  def init(%Lobby{} = lobby) do
    {:ok, lobby}
  end

  @impl GenServer
  def handle_call(:open_games, _from, %Lobby{} = lobby) do
    reply = {:ok, lobby.open_games}
    {:reply, reply, lobby}
  end

  def handle_call(:active_games, _from, %Lobby{} = lobby) do
    reply = {:ok, lobby.active_games}
    {:reply, reply, lobby}
  end

  def handle_call({:open_game, {request, %LobbyGame{} = game}}, _from, %Lobby{} = lobby) do
    # TODO what errors can this call have?
    game_server = GameSupervisor.start_game(request)
    {:ok, new_lobby} = Lobby.open_game(lobby, game)
    LobbyEvents.broadcast_state(new_lobby)
    {:reply, {:ok, game_server}, new_lobby}
  end

  def handle_call({:begin_game, request}, _from, %Lobby{} = lobby) do
    game = GameServer.via_tuple(request.game_id)
    challenge = Map.put(request, :color, :black)

    # TODO what if the game doesn't exist
    with {:ok, _table_view} = success <- GameServer.challenge(game, challenge),
         {:ok, new_lobby} <- Lobby.begin_game(lobby, request.game_id) do
      LobbyEvents.broadcast_state(new_lobby)
      {:reply, success, new_lobby}
    else
      {:error, _reason} = failure -> {:reply, failure, lobby}
    end
  end

  def handle_call({:host_cancel, request}, _from, %Lobby{} = lobby) do
    game = GameServer.via_tuple(request.game_id)

    with {:ok, _table_view} <- GameServer.host_cancel(game, request.token),
         {:ok, new_lobby} <- Lobby.cancel_game(lobby, request.game_id) do
      LobbyEvents.broadcast_state(new_lobby)
      {:reply, :ok, new_lobby}
    else
      {:error, _reason} = failure -> {:reply, failure, lobby}
    end
  end

  def handle_call({:end_game, game_id}, _from, %Lobby{} = lobby) do
    case Lobby.end_game(lobby, game_id) do
      {:ok, new_lobby} ->
        LobbyEvents.broadcast_state(new_lobby)
        {:reply, :ok, new_lobby}

      {:error, _reason} = failure ->
        {:reply, failure, lobby}
    end
  end
end
