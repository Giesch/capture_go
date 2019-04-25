defmodule CaptureGoWeb.LiveLobby do
  use Phoenix.LiveView

  alias CaptureGo.Accounts
  alias CaptureGo.Lobby
  alias CaptureGo.LobbyGame
  alias CaptureGo.LobbyServer
  alias CaptureGoWeb.CreateGameRequest
  alias CaptureGoWeb.Endpoint
  alias CaptureGoWeb.LobbyView
  alias CaptureGoWeb.LobbyAssigns
  alias Phoenix.Socket.Broadcast

  @state_topic "lobby_state"
  @state_event "state_update"

  def broadcast_state(%Lobby{} = lobby) do
    Endpoint.broadcast(@state_topic, @state_event, lobby)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    LobbyView.render("index.html", assigns)
  end

  @impl Phoenix.LiveView
  def mount(%{user_id: user_id}, socket) do
    # TODO find a nice way to handle assigning/using current_user
    #   make a socket auth module?
    current_user = user_id && Accounts.get_user(user_id)
    {:ok, lobby} = LobbyServer.lobby()

    socket = LobbyAssigns.on_mount(socket, current_user, lobby)
    Endpoint.subscribe(@state_topic)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("open_create_game", _value, socket) do
    {:noreply, LobbyAssigns.open_create_game_modal(socket)}
  end

  def handle_event("close_create_game", _value, socket) do
    {:noreply, LobbyAssigns.close_create_game_modal(socket)}
  end

  def handle_event("create_game", %{"create_game_request" => req}, socket) do
    changeset = CreateGameRequest.changeset(req)

    if changeset.valid? do
      user = socket.assigns.current_user
      game = new_game(req, user.username)
      LobbyServer.open_game(game, user.id)
      {:noreply, LobbyAssigns.close_create_game_modal(socket)}
    else
      {:noreply, LobbyAssigns.assign_game_request(socket, req)}
    end
  end

  def handle_event("validate_game", %{"create_game_request" => req}, socket) do
    {:noreply, LobbyAssigns.assign_game_request(socket, req)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        %Broadcast{topic: @state_topic, event: @state_event, payload: lobby},
        socket
      ) do
    {:noreply, LobbyAssigns.assign_games(socket, lobby)}
  end

  defp new_game(%{"game_name" => game_name}, user_name) do
    LobbyGame.new(make_ref(), game_name, user_name, DateTime.utc_now())
  end
end
