defmodule CaptureGo.LobbyServer do
  use GenServer

  alias CaptureGo.Lobby
  alias CaptureGo.GameSupervisor
  alias CaptureGo.GameServer
  alias CaptureGo.LobbyGame
  alias CaptureGoWeb.LiveLobby

  # TODO
  # clean lobby - background job (how often? minutes? days?)
  #   remove inactive tables (as defined by model)
  #   remove invalid/dead game pids
  #   UI for when your game got killed: dump into lobby with error message?

  def start_link(_) do
    GenServer.start_link(__MODULE__, Lobby.new(), name: __MODULE__)
  end

  def lobby() do
    GenServer.call(__MODULE__, :lobby)
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

  defp game_state_request(game_id, player_token, password \\ nil) do
    %{game_id: game_id, token: player_token, password: password}
  end

  ###################################################

  @impl GenServer
  def init(%Lobby{} = lobby) do
    # TODO send self a message to load all games from db
    # also, implement attempting to load a game
    {:ok, lobby}
  end

  @impl GenServer
  def handle_call(:lobby, _from, %Lobby{} = lobby) do
    {:reply, {:ok, lobby}, lobby}
  end

  def handle_call({:open_game, {request, %LobbyGame{} = game}}, _from, %Lobby{} = lobby) do
    # TODO what errors can this call have?
    game_server = GameSupervisor.start_game(request)
    {:ok, new_lobby} = Lobby.open_game(lobby, game)
    LiveLobby.broadcast_state(new_lobby)
    {:reply, {:ok, game_server}, new_lobby}
  end

  def handle_call({:begin_game, request}, _from, %Lobby{} = lobby) do
    game = GameServer.via_tuple(request.game_id)
    challenge = Map.put(request, :color, :black)

    # TODO what if the game doesn't exist
    with {:ok, _table} = success <- GameServer.challenge(game, challenge),
         {:ok, new_lobby} <- Lobby.begin_game(lobby, request.game_id) do
      LiveLobby.broadcast_state(new_lobby)
      {:reply, success, new_lobby}
    else
      {:error, _reason} = failure -> {:reply, failure, lobby}
    end
  end

  def handle_call({:host_cancel, request}, _from, %Lobby{} = lobby) do
    game = GameServer.via_tuple(request.game_id)

    with {:ok, _table} <- GameServer.host_cancel(game, request.token),
         {:ok, new_lobby} <- Lobby.cancel_game(lobby, request.game_id) do
      LiveLobby.broadcast_state(new_lobby)
      {:reply, :ok, new_lobby}
    else
      {:error, _reason} = failure -> {:reply, failure, lobby}
    end
  end

  def handle_call({:end_game, game_id}, _from, %Lobby{} = lobby) do
    case Lobby.end_game(lobby, game_id) do
      {:ok, new_lobby} ->
        LiveLobby.broadcast_state(new_lobby)
        {:reply, :ok, new_lobby}

      {:error, _reason} = failure ->
        {:reply, failure, lobby}
    end
  end
end
