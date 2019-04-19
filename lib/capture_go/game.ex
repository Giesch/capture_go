defmodule CaptureGo.Game do
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

  def start_link(host_token, options \\ []) do
    game_id = Keyword.get(options, :game_id, UUID.uuid4())

    init_arg = %{
      game_id: game_id,
      host_token: host_token,
      options: options
    }

    GenServer.start_link(__MODULE__, init_arg, name: via_tuple(game_id))
  end

  def challenge(game_id, token, color, options \\ [])
      when is_color(color) do
    GenServer.call(via_tuple(game_id), {:challenge, token, color, options})
  end

  def host_cancel(game_id, token) do
    GenServer.call(via_tuple(game_id), {:host_cancel, token})
  end

  def move(game_id, token, point) do
    GenServer.call(via_tuple(game_id), {:move, token, point})
  end

  ########################################

  @impl GenServer
  def init(%{game_id: game_id, host_token: host_token, options: options}) do
    {:ok, Table.new(game_id, host_token, options)}
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

  defp via_tuple(game_id) do
    GameRegistry.via_tuple({__MODULE__, game_id})
  end
end
