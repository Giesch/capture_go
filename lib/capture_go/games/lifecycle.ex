defmodule CaptureGo.Games.Lifecycle do
  @moduledoc """
  Handles the 'meta' rules about the lifecycle of a game.
  """

  alias CaptureGo.Accounts.User
  alias CaptureGo.Games.Game
  alias CaptureGo.Goban

  @error_unauthorized {:error, :unauthorized}

  def challenge(game, challenger_id, password \\ nil)

  def challenge(%Game{state: :open, host_id: host_id}, challenger_id, _password)
      when host_id == challenger_id do
    {:error, :self_challenge}
  end

  def challenge(%Game{state: :open} = game, challenger_id, password) do
    if game_password_valid?(game, password) do
      attrs = %{state: :started, challenger_id: challenger_id}
      {:ok, Game.changeset(game, attrs)}
    else
      @error_unauthorized
    end
  end

  def challenge(%Game{state: state}, _challenger_id, _password) do
    invalid_for_state(state)
  end

  def host_cancel(game, host)

  def host_cancel(%Game{state: :open, host_id: host_id} = game, %User{id: id})
      when host_id == id do
    {:ok, Game.changeset(game, %{state: :cancelled})}
  end

  def host_cancel(%Game{state: :open}, _host) do
    @error_unauthorized
  end

  def host_cancel(%Game{state: state}, _host) do
    invalid_for_state(state)
  end

  def move(game, user_id, point)

  def move(%Game{state: :started} = game, user_id, point) do
    do_move = fn goban, color -> Goban.move(goban, color, point) end
    do_with_player_color(game, user_id, do_move)
  end

  def move(%Game{state: state}, _user_id, _point) do
    invalid_for_state(state)
  end

  def pass(%Game{state: :started} = game, %User{id: user_id}) do
    do_with_player_color(game, user_id, &Goban.pass/2)
  end

  def pass(%Game{state: state}, _user) do
    invalid_for_state(state)
  end

  def resign(game, user_id)

  def resign(%Game{state: :started} = game, user_id) do
    do_with_player_color(game, user_id, &Goban.resign/2)
  end

  def resign(%Game{state: state}, _user_id) do
    invalid_for_state(state)
  end

  ##################################

  # executes a function of the form:
  # goban, color -> {:ok, goban} with the player's color
  # returns a tuple of {:ok, game_changeset}, passing through errors
  defp do_with_player_color(%Game{} = game, user_id, goban_fn) do
    case Game.player_color(game, user_id) do
      {:ok, color} -> apply_goban_fn(game, color, goban_fn)
      {:error, _reason} -> @error_unauthorized
    end
  end

  defp apply_goban_fn(%Game{} = game, color, goban_fn) do
    case goban_fn.(game.goban, color) do
      {:ok, new_goban} -> {:ok, Game.change_goban(game, new_goban)}
      {:error, _reason} = failure -> failure
    end
  end

  defp invalid_for_state(state) do
    {:error, {:invalid_for_state, state}}
  end

  defp game_password_valid?(game, password)

  defp game_password_valid?(%Game{password_hash: nil}, _password) do
    true
  end

  defp game_password_valid?(%Game{} = game, password)
       when is_binary(password) do
    Argon2.verify_pass(password, game.password_hash)
  end

  defp game_password_valid?(%Game{}, _) do
    false
  end
end
