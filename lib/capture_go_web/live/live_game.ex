defmodule CaptureGoWeb.LiveGame do
  use Phoenix.LiveView

  alias CaptureGo.Games
  alias CaptureGo.Games.Game
  alias CaptureGoWeb.Endpoint
  alias CaptureGoWeb.GamesView
  alias Phoenix.LiveView

  @topic_prefix "live_game:"
  @game_change_event "game_change"

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
    socket = on_mount_assigns(socket, current_user, game)
    subscribe_to_game(game_id)
    {:ok, socket}
  end

  defp on_mount_assigns(socket, current_user, game) do
    socket
    |> LiveView.assign(:game, game)
    |> LiveView.assign(:game_topic, game_topic(game))
    |> LiveView.assign(:current_user, current_user)
  end

  defp game_topic(%Game{id: id}) do
    @topic_prefix <> Integer.to_string(id)
  end

  ###############
  # View Events
  #

  @impl LiveView
  def handle_event("make_move:" <> coordinate, _value, socket) do
    [x, y] = String.split(coordinate, ",")
    point = {String.to_integer(x), String.to_integer(y)}
    game = socket.assigns.game
    user = socket.assigns.current_user

    # TODO display errors
    Games.move(game, user, point)

    {:noreply, socket}
  end

  def handle_event("pass", _value, socket) do
    game = socket.assigns.game
    user = socket.assigns.current_user
    Games.pass(game, user)
    {:noreply, socket}
  end

  def handle_event("resign", _value, socket) do
    game = socket.assigns.game
    user = socket.assigns.current_user
    Games.resign(game, user)
    {:noreply, socket}
  end

  ####################
  # PubSub Functions
  #

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
  def handle_info(msg, socket)

  def handle_info(
        %{topic: topic, event: @game_change_event, payload: %Game{} = game},
        %{assigns: %{game_topic: topic}} = socket
      ) do
    {:noreply, LiveView.assign(socket, :game, game)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end
