defmodule CaptureGoWeb.LobbyView do
  use CaptureGoWeb, :view

  def game_link(socket, game) do
    case game.state do
      :open -> challenge_game_link(socket, game)
      _ -> view_game_link(socket, game)
    end
  end

  def view_game_link(socket, game) do
    link("View",
      to: Routes.games_path(socket, :show, game.id),
      class: "button"
    )
  end

  def challenge_game_link(socket, game) do
    link("Challenge",
      to: Routes.challenge_path(socket, :show, game.id),
      class: "button"
    )
  end
end
