defmodule CaptureGoWeb.LiveGame do
  use Phoenix.LiveView

  alias CaptureGo.Games
  alias CaptureGo.Games.Game
  alias CaptureGoWeb.Endpoint
  alias CaptureGoWeb.GamesView
  alias Phoenix.LiveView
  alias CaptureGoWeb.LiveGame.GameAssigns

  ##################
  # View Functions
  #

  def new(conn_or_socket, opts) do
    game_id = Keyword.get(opts, :game_id)
    current_user = Keyword.get(opts, :current_user)

    live_render(conn_or_socket, __MODULE__,
      session: %{current_user: current_user, game_id: game_id}
    )
  end

  @impl LiveView
  def render(assigns) do
    GamesView.render("live_game.html", assigns)
  end

  @impl LiveView
  def mount(%{current_user: current_user, game_id: game_id}, socket) do
    # TODO change this to not throw; return a 404
    game = Games.get_game!(game_id)
    socket = GameAssigns.on_mount(socket, current_user, game)
    subscribe_to_game(game_id)
    {:ok, socket}
  end

  ###############
  # View Events
  #

  @impl LiveView
  def handle_event("make_move:" <> coordinate, _value, socket) do
    point = coord_to_point(coordinate)
    game = socket.assigns.game
    user = socket.assigns.current_user
    # TODO display errors
    Games.move(game, user, point)
    {:noreply, socket}
  end

  defp coord_to_point(coordinate) do
    [x, y] = String.split(coordinate, ",")
    {String.to_integer(x), String.to_integer(y)}
  end

  ####################
  # PubSub Functions
  #

  @topic_prefix "live_game:"
  @game_change_event "game_change"

  def broadcast_game_change(%Game{id: id} = game) do
    Endpoint.broadcast(@topic_prefix <> "#{id}", @game_change_event, game)
  end

  def subscribe_to_game(game_id) when is_binary(game_id) do
    Endpoint.subscribe(@topic_prefix <> game_id)
  end

  def subscribe_to_game(game_id) when is_integer(game_id) do
    Endpoint.subscribe(@topic_prefix <> "#{game_id}")
  end

  def subscribe_to_game(%Game{id: id}) do
    Endpoint.subscribe(@topic_prefix <> "#{id}")
  end

  #################
  # Server Events
  #

  @impl LiveView
  def handle_info(%{topic: @topic_prefix <> game_id} = msg, socket) do
    if String.to_integer(game_id) == socket.assigns.game.id do
      {:noreply, handle_game_event(socket, msg.event, msg.payload)}
    else
      {:noreply, socket}
    end
  end

  def handle_game_event(socket, @game_change_event, %Game{} = game) do
    LiveView.assign(socket, :game, game)
  end

  def handle_game_event(socket, _event, _payload) do
    socket
  end
end
