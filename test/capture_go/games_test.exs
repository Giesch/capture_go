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

      assert game.state == :open
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

    test "creating a game broadcasts it to live_lobby", %{host: host} do
      # these strings must match the module attributes in live_lobby.ex
      topic = "live_lobby"
      event = "new_game"
      CaptureGoWeb.Endpoint.subscribe(topic)

      attrs = %{name: "our game", host_id: host.id}
      assert {:ok, game} = Games.create_game(attrs)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: ^event,
        payload: ^game
      }
    end
  end

  describe "challenge" do
    setup do
      host = user_fixture()
      challenger = user_fixture()
      game = game_fixture(%{host_id: host.id})
      {:ok, host: host, challenger: challenger, game: game}
    end

    test "an open game can be challenged",
         %{game: game, challenger: challenger} do
      assert {:ok, game} = Games.challenge(game, challenger)
      assert game.state == :started
      assert game.challenger_id == challenger.id
    end

    test "a non-open game cannot be challenged",
         %{game: game, challenger: challenger} do
      other_challenger = user_fixture()
      assert {:ok, game} = Games.challenge(game, challenger)
      assert {:error, reason} = Games.challenge(game, other_challenger)
      assert reason == {:invalid_for_state, :started}
    end

    test "a game with a password cannot be challenged without the password",
         %{host: host, challenger: challenger} do
      password = "password"
      game = game_fixture(%{host_id: host.id, password: password})
      assert {:error, :unauthorized} = Games.challenge(game, challenger)
    end

    test "a game with a password can be challenged with the password",
         %{host: host, challenger: challenger} do
      password = "password"
      game = game_fixture(%{host_id: host.id, password: password})
      assert {:ok, game} = Games.challenge(game, challenger, password)
      assert game.state == :started
      assert game.challenger_id == challenger.id
    end

    test "challenging your own game is an error",
         %{host: host, game: game} do
      assert {:error, :self_challenge} == Games.challenge(game, host)
    end

    test "challenging a game broadcasts it to live_lobby",
         %{game: game, challenger: challenger} do
      # these strings must match the module attributes in live_lobby.ex
      topic = "live_lobby"
      event = "started_game"
      CaptureGoWeb.Endpoint.subscribe(topic)

      assert {:ok, game} = Games.challenge(game, challenger)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: ^event,
        payload: ^game
      }
    end
  end

  describe "host_cancel" do
    setup do
      host = user_fixture()
      challenger = user_fixture()
      game = game_fixture(host_id: host.id)
      {:ok, host: host, challenger: challenger, game: game}
    end

    test "the host can cancel their game before it starts",
         %{game: game, host: host} do
      assert game.state == :open
      assert {:ok, game} = Games.host_cancel(game, host)
      assert game.state == :cancelled
    end

    test "other users cannot cancel the game before it starts",
         %{game: game, challenger: challenger} do
      assert game.state == :open
      assert {:error, :unauthorized} == Games.host_cancel(game, challenger)
    end

    test "the host cannot cancel a started game",
         %{game: game, host: host, challenger: challenger} do
      assert game.state == :open
      assert {:ok, game} = Games.challenge(game, challenger)
      assert {:error, reason} = Games.host_cancel(game, host)
      assert {:invalid_for_state, :started} == reason
    end

    test "cancelling a game broadcasts it to live_lobby",
         %{game: game, host: host} do
      # these strings must match the module attributes in live_lobby.ex
      topic = "live_lobby"
      event = "ended_game"
      CaptureGoWeb.Endpoint.subscribe(topic)

      assert {:ok, game} = Games.host_cancel(game, host)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: ^event,
        payload: ^game
      }
    end
  end

  describe "move" do
    setup do
      host = user_fixture()
      challenger = user_fixture()
      game = game_fixture(host_id: host.id)
      {:ok, host: host, challenger: challenger, game: game}
    end

    test "players can make moves on a started game",
         %{game: game, host: host, challenger: challenger} do
      assert {:ok, game} = Games.challenge(game, challenger)
      assert game.state == :started
      assert {:ok, game} = Games.move(game, challenger, {2, 2})
      assert {:ok, game} = Games.move(game, host, {6, 6})
      assert {:ok, :black} == Goban.stone_at(game.goban, {2, 2})
      assert {:ok, :white} == Goban.stone_at(game.goban, {6, 6})
    end

    test "players cannot make moves on a not started game",
         %{game: game, host: host} do
      assert {:error, reason} = Games.move(game, host, {2, 2})
      assert reason == {:invalid_for_state, :open}
    end

    test "players cannot make moves in a game they're not part of",
         %{challenger: challenger, game: game} do
      sneaky = user_fixture()
      assert {:ok, game} = Games.challenge(game, challenger)
      assert game.state == :started
      assert {:error, :unauthorized} == Games.move(game, sneaky, {2, 2})
      assert game.state == :started
    end

    test "winning (by capturing a stone) ends the game",
         %{game: game, host: host, challenger: challenger} do
      assert {:ok, game} = Games.challenge(game, challenger)
      assert game.state == :started

      game = host_wins(game, host, challenger)

      assert game.goban.winner == :white
      assert game.state == :over
    end

    test "players cannot make moves in a game that's over",
         %{game: game, host: host, challenger: challenger} do
      assert {:ok, game} = Games.challenge(game, challenger)
      assert game.state == :started

      game = host_wins(game, host, challenger)
      assert game.state == :over

      assert {:error, reason} = Games.move(game, challenger, {3, 3})
      assert reason == {:invalid_for_state, :over}
    end

    test "winning a game broadcasts to live_lobby",
         %{game: game, host: host, challenger: challenger} do
      # these strings must match the module attributes in live_lobby.ex
      topic = "live_lobby"
      event = "ended_game"
      CaptureGoWeb.Endpoint.subscribe(topic)

      assert {:ok, game} = Games.challenge(game, challenger)
      assert game.state == :started
      game = host_wins(game, host, challenger)

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: ^event,
        payload: ^game
      }
    end

    def host_wins(game, host, challenger) do
      assert {:ok, game} = Games.move(game, challenger, {0, 0})
      assert {:ok, game} = Games.move(game, host, {1, 0})
      assert {:ok, game} = Games.move(game, challenger, {8, 8})
      assert {:ok, game} = Games.move(game, host, {0, 1})
      game
    end
  end

  describe "lobby" do
    setup do
      host = user_fixture()
      challenger = user_fixture()
      {:ok, host: host, challenger: challenger}
    end

    test "newly created games appear in open games",
         %{host: host} do
      assert {:ok, %{open_games: open_games}} = Games.lobby()
      assert Enum.empty?(open_games)

      game = game_fixture(host_id: host.id)
      assert {:ok, %{open_games: open_games}} = Games.lobby()
      assert Enum.any?(open_games, fn g -> game.id == g.id end)
    end

    test "challenged games move into active_games",
         %{host: host, challenger: challenger} do
      assert {:ok, %{open_games: open_games}} = Games.lobby()
      assert Enum.empty?(open_games)

      game_1 = game_fixture(host_id: host.id)
      game_2 = game_fixture(host_id: host.id)
      assert {:ok, game_1} = Games.challenge(game_1, challenger)

      assert {:ok, %{open_games: open_games, active_games: active_games}} = Games.lobby()

      contains_game_1? = fn games ->
        Enum.any?(games, fn g -> game_1.id == g.id end)
      end

      contains_game_2? = fn games ->
        Enum.any?(games, fn g -> game_2.id == g.id end)
      end

      refute contains_game_1?.(open_games)
      assert contains_game_1?.(active_games)

      assert contains_game_2?.(open_games)
      refute contains_game_2?.(active_games)
    end
  end
end
