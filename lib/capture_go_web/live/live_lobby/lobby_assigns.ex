defmodule CaptureGoWeb.LiveLobby.LobbyAssigns do
  @moduledoc """
  Manages the socket assigns for LiveLobby.
  Assigns:
    :current_user
    :open_games
    :active_games
    :create_game_modal_open
    :create_game_request
  """

  alias CaptureGoWeb.LiveLobby.CreateGameRequest
  alias Phoenix.LiveView

  def on_mount(socket, current_user, lobby) do
    socket
    |> LiveView.assign(:current_user, current_user)
    |> assign_game_request()
    |> close_create_game_modal()
    |> assign_games(lobby.open_games, lobby.active_games)
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

  def new_game(socket, game) do
    open_games = [game | socket.assigns.open_games]
    LiveView.assign(socket, :open_games, open_games)
  end

  def start_game(socket, game) do
    keep = fn g -> g.id != game.id end
    open_games = Enum.filter(socket.assigns.open_games, keep)
    active_games = [game | socket.assigns.active_games]

    assign_games(socket, open_games, active_games)
  end

  def remove_game(socket, game) do
    keep = fn g -> g.id != game.id end
    open_games = Enum.filter(socket.assigns.open_games, keep)
    active_games = Enum.filter(socket.assigns.active_games, keep)

    assign_games(socket, open_games, active_games)
  end

  defp assign_games(socket, open_games, active_games) do
    socket
    |> LiveView.assign(:open_games, open_games)
    |> LiveView.assign(:active_games, active_games)
  end
end
