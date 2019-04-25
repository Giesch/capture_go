defmodule CaptureGo.GameServer do
  @moduledoc """
  The stateful server wrapper for CaptureGo.GameTable
  """

  use GenServer

  import CaptureGo.ColorUtils
  alias CaptureGo.GameTable
  alias CaptureGo.GameRegistry
  alias CaptureGo.LobbyServer

  # TODO
  # add broadcasts of the game state for live view
  # handle players leaving; have the game time out due to inactivity
  #   use update_activity when doing other tasks (make part of data model?)
  #   background job to clean out inactive games
  #   add inactive?(now) predicate to model

  def start_link(options \\ []) do
    game_id = Keyword.get(options, :game_id)

    init_arg = %{
      game_id: game_id,
      token: Keyword.get(options, :token),
      password: Keyword.get(options, :password)
    }

    GenServer.start_link(__MODULE__, init_arg, name: via_tuple(game_id))
  end

  def challenge(game_server, %{token: token, color: color} = request)
      when is_color(color) do
    GenServer.call(game_server, {:challenge, token, color, request[:password]})
  end

  def host_cancel(game_server, token) do
    GenServer.call(game_server, {:host_cancel, token})
  end

  def move(game_server, token, point) do
    GenServer.call(game_server, {:move, token, point})
  end

  def via_tuple(game_id) do
    GameRegistry.via_tuple({__MODULE__, game_id})
  end

  ########################################

  @impl GenServer
  def init(%{game_id: game_id, token: token, password: password}) do
    {:ok, GameTable.new(game_id, token, password)}
  end

  @impl GenServer
  def handle_call({:challenge, token, color, password}, _from, table_state) do
    GameTable.challenge(table_state, token, color, password)
    |> pass_through_reply(table_state)
  end

  def handle_call({:host_cancel, token}, _from, table_state) do
    GameTable.host_cancel(table_state, token)
    |> pass_through_reply(table_state)
  end

  def handle_call({:move, token, point}, _from, table_state) do
    GameTable.move(table_state, token, point)
    |> game_over_check()
    |> pass_through_reply(table_state)
  end

  defp game_over_check({:ok, %GameTable{state: :game_over} = table} = result) do
    LobbyServer.end_game(table.game_id)
    result
  end

  defp game_over_check(result) do
    result
  end

  defp pass_through_reply(result, current_table) do
    case result do
      {:ok, new_table} = success -> {:reply, success, new_table}
      {:error, _reason} = failure -> {:reply, failure, current_table}
    end
  end
end
