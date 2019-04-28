defmodule CaptureGoWeb.LiveGame.GameAssigns do
  alias Phoenix.LiveView

  def on_mount(socket, current_user, game) do
    socket
    |> LiveView.assign(:game, game)
    |> LiveView.assign(:current_user, current_user)
  end
end
