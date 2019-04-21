defmodule CaptureGo.LobbyServer do
  use GenServer

  alias CaptureGo.Lobby
  alias CaptureGo.GameSupervisor
  alias CaptureGo.GameServer

  # TODO
  # publish game state changes to a lobby channel
  # clean lobby - background job
  #   remove inactive tables (as defined by model)
  #   remove invalid/dead game pids
  #   UI for when your game got killed: dump into lobby with error message?

  def start_link(_) do
    GenServer.start_link(__MODULE__, Lobby.new(), name: __MODULE__)
  end

  def open_games() do
    GenServer.call(__MODULE__, :open_games)
  end

  def active_games() do
    GenServer.call(__MODULE__, :active_games)
  end

  def open_game(game_id, host_token, password \\ nil) do
    request = game_state_request(game_id, host_token, password)
    GenServer.call(__MODULE__, {:open_game, request})
  end

  def begin_game(game_id, challenger_token, password \\ nil) do
    request = game_state_request(game_id, challenger_token, password)
    GenServer.call(__MODULE__, {:begin_game, request})
  end

  def host_cancel(game_id, host_token) do
    request = game_state_request(game_id, host_token)
    GenServer.call(__MODULE__, {:host_cancel, request})
  end

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

  def handle_call({:open_game, request}, _from, %Lobby{} = lobby) do
    # TODO what errors can this call have?
    game_server = GameSupervisor.start_game(request)
    {:ok, lobby} = Lobby.open_game(lobby, request.game_id)
    {:reply, {:ok, game_server}, lobby}
  end

  def handle_call({:begin_game, request}, _from, %Lobby{} = lobby) do
    game = GameServer.via_tuple(request.game_id)
    challenge = Map.put(request, :color, :black)

    with {:ok, _table_view} = success <- GameServer.challenge(game, challenge),
         {:ok, new_lobby} <- Lobby.begin_game(lobby, request.game_id) do
      {:reply, success, new_lobby}
    else
      {:error, _reason} = failure -> {:reply, failure, lobby}
    end
  end

  def handle_call({:host_cancel, request}, _from, %Lobby{} = lobby) do
    game = GameServer.via_tuple(request.game_id)

    with {:ok, _table_view} <- GameServer.host_cancel(game, request.token),
         {:ok, new_lobby} <- Lobby.close_game(lobby, request.game_id) do
      {:reply, :ok, new_lobby}
    else
      {:error, _reason} = failure -> {:reply, failure, lobby}
    end
  end
end
