defmodule CaptureGoWeb.LiveLobby do
  use Phoenix.LiveView

  alias CaptureGo.Accounts
  alias CaptureGo.Games
  alias CaptureGo.Games.Game
  alias CaptureGoWeb.Endpoint
  alias CaptureGoWeb.LiveLobby.CreateGameRequest
  alias CaptureGoWeb.LiveLobby.LobbyAssigns
  alias CaptureGoWeb.LobbyView
  alias Phoenix.LiveView

  ##################
  # View Functions
  #

  @impl LiveView
  def render(assigns) do
    LobbyView.render("index.html", assigns)
  end

  @impl LiveView
  def mount(%{user_id: user_id}, socket) do
    # TODO find a nice way to handle assigning/using current_user
    #   make a socket auth module?
    current_user = user_id && Accounts.get_user(user_id)
    {:ok, lobby} = Games.lobby()
    socket = LobbyAssigns.on_mount(socket, current_user, lobby)
    subscribe_to_lobby()
    {:ok, socket}
  end

  ###############
  # View Events
  #

  @impl LiveView
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
      create_game(req, user)
      {:noreply, LobbyAssigns.close_create_game_modal(socket)}
    else
      {:noreply, LobbyAssigns.assign_game_request(socket, req)}
    end
  end

  def handle_event("validate_game", %{"create_game_request" => req}, socket) do
    {:noreply, LobbyAssigns.assign_game_request(socket, req)}
  end

  defp create_game(%{"game_name" => name} = _request, host) do
    attrs = %{name: name, host_id: host.id}
    Games.create_game(attrs)
  end

  ####################
  # PubSub Functions
  #

  @topic "live_lobby"

  @new_game_event "new_game"
  @started_game_event "started_game"
  @ended_game_event "ended_game"

  def broadcast_new_game(%Game{} = game) do
    Endpoint.broadcast(@topic, @new_game_event, game)
  end

  def broadcast_started_game(%Game{} = game) do
    Endpoint.broadcast(@topic, @started_game_event, game)
  end

  def broadcast_ended_game(%Game{} = game) do
    Endpoint.broadcast(@topic, @ended_game_event, game)
  end

  def subscribe_to_lobby() do
    Endpoint.subscribe(@topic)
  end

  #################
  # Server Events
  #

  @impl LiveView
  def handle_info(%{topic: @topic, payload: game} = msg, socket) do
    {:noreply, handle_game_event(socket, msg.event, game)}
  end

  defp handle_game_event(socket, @new_game_event, %Game{} = game) do
    LobbyAssigns.new_game(socket, game)
  end

  defp handle_game_event(socket, @started_game_event, %Game{} = game) do
    LobbyAssigns.start_game(socket, game)
  end

  defp handle_game_event(socket, @ended_game_event, %Game{} = game) do
    LobbyAssigns.remove_game(socket, game)
  end
end
