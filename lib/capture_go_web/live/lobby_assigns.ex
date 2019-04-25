defmodule CaptureGoWeb.LobbyAssigns do
  @moduledoc """
  Manages the socket assigns for LiveLobby.
  Assigns:
    :current_user
    :open_games
    :active_games
    :create_game_modal_open
    :create_game_request
  """

  alias CaptureGoWeb.CreateGameRequest
  alias Phoenix.LiveView

  def on_mount(socket, current_user, lobby) do
    socket
    |> LiveView.assign(:current_user, current_user)
    |> assign_game_request()
    |> close_create_game_modal()
    |> assign_games(lobby)
  end

  def assign_games(socket, lobby) do
    socket
    |> LiveView.assign(:open_games, sort_games(lobby.open_games))
    |> LiveView.assign(:active_games, sort_games(lobby.active_games))
  end

  def open_create_game_modal(socket) do
    socket
    |> assign_game_request()
    |> LiveView.assign(:create_game_modal_open, true)
  end

  def close_create_game_modal(socket) do
    LiveView.assign(socket, :create_game_modal_open, false)
  end

  def assign_game_request(socket, params \\ %{}) do
    changeset = CreateGameRequest.changeset(params)
    LiveView.assign(socket, :create_game_request, changeset)
  end

  defp sort_games(lobby_games_map) do
    lobby_games_map
    |> Map.values()
    |> Enum.sort_by(
      fn lobby_game -> lobby_game.created_at end,
      fn x, y -> DateTime.compare(x, y) == :gt end
    )
  end
end
