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
    case Game.player_color(game, user_id) do
      {:ok, color} -> do_move(game, color, point)
      {:error, _reason} -> @error_unauthorized
    end
  end

  def move(%Game{state: state}, _user_id, _point) do
    invalid_for_state(state)
  end

  defp do_move(%Game{goban: goban} = game, color, point) do
    case Goban.move(goban, color, point) do
      {:ok, goban} ->
        attrs = win_check(goban)
        {:ok, Game.changeset(game, attrs)}

      {:error, _reason} = failure ->
        failure
    end
  end

  defp win_check(%Goban{} = goban) do
    if goban.winner do
      %{goban: goban, state: :over}
    else
      %{goban: goban}
    end
  end

  defp invalid_for_state(state) do
    {:error, {:invalid_for_state, state}}
  end

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
