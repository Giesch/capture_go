defmodule CaptureGo.LiveGameTest do
  use CaptureGo.DataCase

  alias CaptureGoWeb.LiveGame
  alias Phoenix.LiveView.Socket
  alias CaptureGo.Games.Game

  describe "handle_info" do
    @game_change_event "game_change"
    @game_topic "game_topic"

    test "handle info works with a matching topic" do
      game = %Game{}
      msg = %{topic: @game_topic, event: @game_change_event, payload: game}
      socket = %Socket{assigns: %{game_topic: @game_topic, game: %{}}}

      assert {:noreply, new_socket} = LiveGame.handle_info(msg, socket)
      assert new_socket.assigns.game == game
    end

    test "handle info ignores a non-matching topic" do
      game = %Game{}
      msg = %{topic: "some other game", event: @game_change_event, payload: game}
      socket = %Socket{assigns: %{game_topic: @game_topic, game: %{}}}

      assert {:noreply, new_socket} = LiveGame.handle_info(msg, socket)
      refute new_socket.assigns.game == game
    end
  end
end
