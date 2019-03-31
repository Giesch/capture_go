defmodule CaptureGo.Table do
  alias CaptureGo.Table
  alias CaptureGo.Goban
  import CaptureGo.Color

  # state is an enum of:
  # :table_open
  # :game_started
  # :game_over
  # :host_cancelled

  # :player_left (necessary? allow rejoining?)

  # TODO split out game state & authorization into submodules?

  defstruct state: :table_open,
            goban: Goban.new(),
            host_token: nil,
            password: nil,
            challenger_token: nil,
            challenger_color: nil

  def new(host_token, options \\ []) do
    password = Keyword.get(options, :password)
    %Table{host_token: host_token, password: password}
  end

  def challenge(table, token, color, opts \\ [])

  def challenge(%Table{state: :table_open, password: password} = table, token, color, opts)
      when is_color(color) do
    provided_pass = Keyword.get(opts, :password)

    if password && provided_pass != password do
      {:error, :unauthorized}
    else
      {:ok, start_game(table, token, color)}
    end
  end

  def challenge(%Table{state: state}, _token, _color, _opts) do
    invalid_for_state(state)
  end

  defp start_game(table, token, color) do
    %Table{
      table
      | state: :game_started,
        challenger_token: token,
        challenger_color: color
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

  # TODO game over state
  # functions for making moves
  # game over checks in the make move function
  # player left

  defp invalid_for_state(state) do
    {:error, {:invalid_for_state, state}}
  end
end
