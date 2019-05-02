defmodule CaptureGoWeb.LiveGame.GameAssigns do
  alias Phoenix.LiveView

  def on_mount(socket, current_user, game, topic_prefix) do
    socket
    |> LiveView.assign(:game, game)
    |> LiveView.assign(:game_topic, topic_prefix <> Integer.to_string(game.id))
    |> LiveView.assign(:current_user, current_user)
  end
end
