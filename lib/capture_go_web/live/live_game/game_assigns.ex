defmodule CaptureGoWeb.LiveGame.GameAssigns do
  alias Phoenix.LiveView

  def on_mount(socket, current_user, game, game_topic) do
    socket
    |> LiveView.assign(:game, game)
    |> LiveView.assign(:game_topic, game_topic)
    |> LiveView.assign(:current_user, current_user)
  end
end
