defmodule CaptureGo.Game do
  @moduledoc """
  The stateful server wrapper for CaptureGo.Table
  """

  use GenServer

  import CaptureGo.Color
  alias CaptureGo.Table
  alias CaptureGo.TableView

  # TODO
  # add timeouts
  # replace :ok reply with something useful
  #   maybe just the board?
  #   or a new struct that copies public stuff from board
  # decide where to generate/handle the tokens
  #   also need to tell client their token

  def start_link(host_token, options \\ []) do
    GenServer.start_link(__MODULE__, {host_token, options})
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

  ########################################

  @impl GenServer
  def init({host_token, options}) do
    {:ok, Table.new(host_token, options)}
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
