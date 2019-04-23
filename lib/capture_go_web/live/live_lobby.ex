defmodule CaptureGoWeb.LiveLobby do
  use Phoenix.LiveView

  alias CaptureGo.LobbyServer
  alias CaptureGo.LobbyEvents
  alias CaptureGoWeb.LobbyView

  @impl Phoenix.LiveView
  def render(assigns) do
    LobbyView.render("index.html", assigns)
  end

  @impl Phoenix.LiveView
  def mount(_session, socket) do
    {:ok, lobby} = LobbyServer.lobby()
    socket = assign(socket, :lobby, lobby)

    # TODO handle lobby state subscription
    LobbyEvents.subscribe()

    {:ok, socket}
  end
end
