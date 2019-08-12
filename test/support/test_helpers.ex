defmodule CaptureGo.TestHelpers do
  alias CaptureGo.Accounts
  alias CaptureGo.Games

  def user_fixture(attrs \\ %{}) do
    username = "user_#{System.unique_integer([:positive])}"

    defaults = %{
      username: username,
      password: attrs[:password] || "supersecret"
    }

    {:ok, user} =
      attrs
      |> Enum.into(defaults)
      |> Accounts.register_user()

    user
  end

  def game_fixture(attrs \\ %{}) do
    game_name = "game_#{System.unique_integer([:positive])}"

    defaults = %{
      name: game_name
    }

    {:ok, game} =
      attrs
      |> Enum.into(defaults)
      |> Games.create_game()

    game
  end
end
