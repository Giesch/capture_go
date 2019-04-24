defmodule CaptureGoWeb.LiveLobby do
  use Phoenix.LiveView

  alias CaptureGo.LobbyServer
  alias CaptureGoWeb.LobbyView
  alias CaptureGoWeb.Endpoint
  alias CaptureGo.Lobby

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
  def mount(_session, socket) do
    {:ok, lobby} = LobbyServer.lobby()
    Endpoint.subscribe(@state_topic)
    {:ok, assign(socket, :lobby, lobby)}
  end

  @impl Phoenix.LiveView
  def handle_info(%{topic: @state_topic, payload: lobby}, socket) do
    {:noreply, assign(socket, :lobby, lobby)}
  end
end
