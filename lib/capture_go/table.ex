defmodule CaptureGo.Table do
  @moduledoc """
  A data type for the 'meta' rules of the game.

  Table.state is an enum of:
    :table_open
    :game_started
    :host_cancelled
    :game_over
  """

  alias CaptureGo.Table
  alias CaptureGo.Goban
  import CaptureGo.Color

  # TODO handle players leaving; have the game time out due to inactivity
  # :player_left (necessary? allow rejoining?)
  # timestamp for last move/last interaction
  # to be used for cleaning up left games

  defstruct state: :table_open,
            goban: Goban.new(),
            host_token: nil,
            password: nil,
            challenger_token: nil,
            player_colors: Map.new(),
            last_activity: nil

  def new(host_token, options \\ []) do
    password = Keyword.get(options, :password)
    %Table{host_token: host_token, password: password}
  end

  def challenge(table, token, color, opts \\ [])

  def challenge(%Table{state: :table_open} = table, token, color, opts)
      when is_color(color) do
    provided_pass = Keyword.get(opts, :password)

    if table.password && provided_pass != table.password do
      {:error, :unauthorized}
    else
      {:ok, start_game(table, token, color)}
    end
  end

  def challenge(%Table{state: state}, _token, _color, _opts) do
    invalid_for_state(state)
  end

  defp start_game(table, challenger_token, challenger_color) do
    %Table{
      table
      | state: :game_started,
        challenger_token: challenger_token,
        player_colors: %{
          challenger_token => challenger_color,
          table.host_token => opposite_color(challenger_color)
        }
    }
  end

  def host_cancel(%Table{state: :table_open, host_token: host} = table, token)
      when token == host do
    table = %Table{table | state: :host_cancelled}
    {:ok, table}
  end

  def host_cancel(%Table{state: :table_open}, _token) do
    {:error, :unauthorized}
  end

  def host_cancel(%Table{state: state}, _token) do
    invalid_for_state(state)
  end

  def move(%Table{state: :game_started} = table, token, point) do
    color = table.player_colors[token]

    if color do
      make_move(table, color, point)
    else
      {:error, :unauthorized}
    end
  end

  def move(%Table{state: state}, _token, _point) do
    invalid_for_state(state)
  end

  defp make_move(table, color, point) do
    case Goban.move(table.goban, color, point) do
      {:ok, goban} ->
        table = %Table{table | goban: goban} |> win_check()
        {:ok, table}

      failure ->
        failure
    end
  end

  defp win_check(%Table{goban: goban} = table) do
    if goban.winner do
      %Table{table | state: :game_over}
    else
      table
    end
  end

  def update_activity(%Table{} = table, time) do
    %Table{table | last_activity: time}
  end

  defp invalid_for_state(state) do
    {:error, {:invalid_for_state, state}}
  end
end
