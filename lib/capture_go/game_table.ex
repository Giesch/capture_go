defmodule CaptureGo.GameTable do
  @moduledoc """
  A data type for the 'meta' rules of the game.

  Table.state is an enum of:
    :table_open
    :game_started
    :host_cancelled
    :game_over
  """

  # TODO allow resignation

  alias CaptureGo.GameTable
  alias CaptureGo.Goban
  import CaptureGo.ColorUtils

  defstruct state: :table_open,
            goban: Goban.new(),
            game_id: nil,
            host_token: nil,
            password: nil,
            challenger_token: nil,
            player_colors: Map.new(),
            last_activity: nil

  def new(game_id, host_token, password \\ nil) do
    %GameTable{game_id: game_id, host_token: host_token, password: password}
  end

  def challenge(table, token, color, password \\ nil)

  def challenge(%GameTable{state: :table_open} = table, token, color, password)
      when is_color(color) do
    check_password_and_start(table, password, token, color)
  end

  def challenge(%GameTable{state: state}, _token, _color, _password) do
    invalid_for_state(state)
  end

  defp check_password_and_start(%GameTable{} = table, password, token, color) do
    if table.password && password != table.password do
      {:error, :unauthorized}
    else
      {:ok, start_game(table, token, color)}
    end
  end

  defp start_game(table, challenger_token, challenger_color) do
    %GameTable{
      table
      | state: :game_started,
        challenger_token: challenger_token,
        player_colors: %{
          challenger_token => challenger_color,
          table.host_token => opposite_color(challenger_color)
        }
    }
  end

  def host_cancel(%GameTable{state: :table_open, host_token: host} = table, token)
      when token == host do
    table = %GameTable{table | state: :host_cancelled}
    {:ok, table}
  end

  def host_cancel(%GameTable{state: :table_open}, _token) do
    {:error, :unauthorized}
  end

  def host_cancel(%GameTable{state: state}, _token) do
    invalid_for_state(state)
  end

  def move(%GameTable{state: :game_started} = table, token, point) do
    color = table.player_colors[token]

    if color do
      make_move(table, color, point)
    else
      {:error, :unauthorized}
    end
  end

  def move(%GameTable{state: state}, _token, _point) do
    invalid_for_state(state)
  end

  defp make_move(table, color, point) do
    case Goban.move(table.goban, color, point) do
      {:ok, goban} ->
        table = %GameTable{table | goban: goban} |> win_check()
        {:ok, table}

      {:error, _reason} = failure ->
        failure
    end
  end

  defp win_check(%GameTable{goban: goban} = table) do
    if goban.winner do
      %GameTable{table | state: :game_over}
    else
      table
    end
  end

  def update_activity(%GameTable{} = table, time) do
    %GameTable{table | last_activity: time}
  end

  defp invalid_for_state(state) do
    {:error, {:invalid_for_state, state}}
  end
end