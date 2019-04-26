defmodule CaptureGo.Games.GameTest do
  use CaptureGo.DataCase

  import CaptureGo.ColorUtils
  alias CaptureGo.Games
  alias CaptureGo.Games.Game
  import CaptureGo.TestHelpers

  describe "participant?" do
    setup do
      host = user_fixture()
      challenger = user_fixture()
      game = game_fixture(%{host_id: host.id})
      {:ok, host: host, challenger: challenger, game: game}
    end

    test "the host is a participant",
         %{game: game, host: host, challenger: challenger} do
      assert Game.participant?(game, host.id)
      assert {:ok, game} = Games.challenge(game, challenger)
      assert Game.participant?(game, host.id)
    end

    test "the challenger is a participant",
         %{game: game, challenger: challenger} do
      refute Game.participant?(game, challenger.id)
      assert {:ok, game} = Games.challenge(game, challenger)
      assert Game.participant?(game, challenger.id)
    end

    test "other users are not participants",
         %{game: game, challenger: challenger} do
      sneaky = user_fixture()
      refute Game.participant?(game, sneaky.id)
      assert {:ok, game} = Games.challenge(game, challenger)
      refute Game.participant?(game, sneaky.id)
    end

    test "a nil user id is not a participant",
         %{game: game, challenger: challenger} do
      refute Game.participant?(game, nil)
      assert {:ok, game} = Games.challenge(game, challenger)
      refute Game.participant?(game, nil)
    end
  end

  describe "player_color" do
    setup do
      host = user_fixture()
      challenger = user_fixture()
      game = game_fixture(%{host_id: host.id})
      assert {:ok, game} = Games.challenge(game, challenger)
      {:ok, host: host, challenger: challenger, game: game}
    end

    test "the host has the host color",
         %{game: game, host: host} do
      assert {:ok, color} = Game.player_color(game, host.id)
      assert color == game.host_color
    end

    test "the challenger has the opposite of the host color",
         %{game: game, challenger: challenger} do
      assert {:ok, color} = Game.player_color(game, challenger.id)
      assert color == opposite_color(game.host_color)
    end

    test "player color of a non-participant is an error",
         %{game: game} do
      sneaky = user_fixture()
      assert {:error, :not_participant} == Game.player_color(game, sneaky.id)
    end
  end
end
