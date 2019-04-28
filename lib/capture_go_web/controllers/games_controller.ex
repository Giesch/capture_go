defmodule CaptureGoWeb.GamesController do
  use CaptureGoWeb, :controller

  def show(conn, %{"id" => game_id}) do
    render(conn, "index.html", game_id: game_id)
  end
end
