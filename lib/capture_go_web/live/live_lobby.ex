defmodule CaptureGoWeb.LiveLobby do
  use Phoenix.LiveView

  alias CaptureGo.LobbyServer
  alias CaptureGoWeb.LobbyView
  alias CaptureGoWeb.Endpoint
  alias CaptureGo.Lobby
  alias CaptureGo.LobbyGame
  alias CaptureGo.Accounts

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

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign_games(lobby)

    Endpoint.subscribe(@state_topic)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("create_game", _value, socket) do
    user = socket.assigns.current_user
    game = new_game("New Game", user.username)
    LobbyServer.open_game(game, user.id)
    {:noreply, socket}
  end

  defp new_game(game_name, user_name) do
    LobbyGame.new(make_ref(), game_name, user_name, DateTime.utc_now())
  end

  @impl Phoenix.LiveView
  def handle_info(%{topic: @state_topic, payload: lobby}, socket) do
    {:noreply, assign_games(socket, lobby)}
  end

  defp assign_games(socket, lobby) do
    socket
    |> assign(:open_games, sort_games(lobby.open_games))
    |> assign(:active_games, sort_games(lobby.active_games))
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
