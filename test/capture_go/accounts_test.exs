defmodule CaptureGo.AccountsTest do
  use CaptureGo.DataCase

  import CaptureGo.TestHelpers
  alias CaptureGo.Accounts
  alias CaptureGo.Accounts.User

  describe "users" do
    @valid_attrs %{
      email: "some email",
      password: "some password",
      username: "some username"
    }

    @update_attrs %{
      email: "some updated email",
      password: "some updated password",
      username: "some updated username"
    }

    @invalid_attrs %{email: nil, password: nil, username: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      [result] = Accounts.list_users()
      assert result.username == user.username
      assert result.email == user.email
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      result = Accounts.get_user!(user.id)
      assert result.username == user.username
      assert result.email == user.email
    end

    test "register_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.register_user(@valid_attrs)
      assert user.email == "some email"
      assert user.username == "some username"
    end

    test "register_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.register_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some updated email"
      assert user.username == "some updated username"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      result = Accounts.get_user!(user.id)
      assert result.username == user.username
      assert result.email == user.email
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "authenticate_by_email_and_password/2" do
    @username "user"
    @email "user@localhost"
    @pass "123456"

    setup do
      user = user_fixture(username: @username, email: @email, password: @pass)
      {:ok, user: user}
    end

    test "returns user with correct password", %{user: %User{id: id}} do
      result = Accounts.authenticate_by_email_and_password(@email, @pass)
      assert {:ok, %User{id: ^id}} = result
    end

    test "returns unauthorized error with invalid password" do
      result = Accounts.authenticate_by_email_and_password(@email, "badpass")
      assert {:error, :unauthorized} == result
    end

    test "returns not found error with no matching user for email" do
      result = Accounts.authenticate_by_email_and_password("badmail@localhost", @pass)
      assert {:error, :not_found} == result
    end
  end
end
