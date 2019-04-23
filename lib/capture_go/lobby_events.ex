defmodule CaptureGo.LobbyEvents do
  alias CaptureGoWeb.Endpoint
  alias CaptureGo.Lobby

  @state_topic "lobby_state"
  @state_event "state_update"

  # TODO this subscribe function isn't useful, i think
  # we can't encapsulate it, because the client still needs to
  # match on the topic, event, payload in their handle_info
  # is it still nice for convenience?

  def subscribe() do
    Endpoint.subscribe(@state_topic)
  end

  def broadcast_state(%Lobby{} = lobby) do
    Endpoint.broadcast(@state_topic, @state_event, lobby)
  end
end
