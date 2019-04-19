defmodule CaptureGo.TestHelpers do
  alias CaptureGo.Accounts

  def user_fixture(attrs \\ %{}) do
    username = "user#{System.unique_integer([:positive])}"

    defaults = %{
      username: username,
      email: attrs[:email] || "#{username}@example.com",
      password: attrs[:password] || "supersecret"
    }

    {:ok, user} =
      attrs
      |> Enum.into(defaults)
      |> Accounts.register_user()

    user
  end
end
