defmodule CaptureGo.GamesTest do
  use CaptureGo.DataCase

  import CaptureGo.TestHelpers
  alias CaptureGo.Games
  alias CaptureGo.Goban

  describe "create_game" do
    setup do
      host = user_fixture()
      {:ok, host: host}
    end

    test "a new game has the correct defaults", %{host: host} do
      attrs = %{
        name: "our game",
        host_id: host.id
      }

      assert {:ok, game} = Games.create_game(attrs)

      assert game.lifecycle_state == :open
      assert game.host_color == :white
      assert game.goban == Goban.new()

      assert game.name == "our game"
      assert game.host_id == host.id
    end

    test "a missing host is an error" do
      attrs = %{name: "our game"}
      assert {:error, changeset} = Games.create_game(attrs)
      assert %{host_id: ["can't be blank"]} == errors_on(changeset)
    end

    test "a missing game name is an error", %{host: host} do
      attrs = %{host_id: host.id}
      assert {:error, changeset} = Games.create_game(attrs)
      assert %{name: ["can't be blank"]} == errors_on(changeset)
    end
  end
end
