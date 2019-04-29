defmodule CaptureGoWeb.ChallengeController do
  use CaptureGoWeb, :controller

  alias CaptureGo.Games
  alias CaptureGoWeb.GamesView
  import CaptureGoWeb.LiveRedirect, only: [lobby_redirect: 1]

  def show(conn, %{"id" => game_id}) do
    game_id = String.to_integer(game_id)

    case Games.challenge(game_id, conn.assigns.current_user) do
      {:ok, game} ->
        render(conn, GamesView, "index.html", game_id: game.id)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Unable to challenge game: #{reason}")
        |> lobby_redirect()
    end
  end
end
