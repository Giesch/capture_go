defmodule CaptureGo.GameServer do
  @moduledoc """
  The stateful server wrapper for CaptureGo.Table
  """

  use GenServer

  import CaptureGo.Color
  alias CaptureGo.Table
  alias CaptureGo.TableView
  alias CaptureGo.GameRegistry

  # TODO
  # add channel broadcasts;
  #   need another module that handles channel names
  # handle players leaving; have the game time out due to inactivity
  #   use update_activity when doing other tasks (make part of data model?)
  #   background job to clean out inactive games
  #   add inactive?(now) predicate to model

  def start_link(options \\ []) do
    game_id = Keyword.get(options, :game_id)

    init_arg = %{
      game_id: game_id,
      host_token: Keyword.get(options, :host_token),
      password: Keyword.get(options, :password)
    }

    GenServer.start_link(__MODULE__, init_arg, name: via_tuple(game_id))
  end

  def challenge(game_server, token, color, options \\ [])
      when is_color(color) do
    GenServer.call(game_server, {:challenge, token, color, options})
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
  def init(%{game_id: game_id, host_token: host_token, password: password})
      when is_binary(game_id) and is_binary(host_token) do
    {:ok, Table.new(game_id, host_token, password)}
  end

  @impl GenServer
  def handle_call({:challenge, token, color, options}, _from, table_state) do
    Table.challenge(table_state, token, color, options)
    |> pass_through_reply(table_state)
  end

  def handle_call({:host_cancel, token}, _from, table_state) do
    Table.host_cancel(table_state, token)
    |> pass_through_reply(table_state)
  end

  def handle_call({:move, token, point}, _from, table_state) do
    Table.move(table_state, token, point)
    |> pass_through_reply(table_state)
  end

  defp pass_through_reply(result, current_table) do
    case result do
      {:ok, table} -> {:reply, {:ok, TableView.new(table)}, table}
      {:error, _reason} = failure -> {:reply, failure, current_table}
    end
  end
end
