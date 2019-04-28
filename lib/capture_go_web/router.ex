defmodule CaptureGoWeb.Router do
  use CaptureGoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CaptureGoWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CaptureGoWeb do
    pipe_through :browser

    live "/", LiveLobby, session: [:user_id], as: "lobby"
    resources "/games", GamesController, only: [:show]

    resources "/users", UserController, only: [:new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
  end
end
