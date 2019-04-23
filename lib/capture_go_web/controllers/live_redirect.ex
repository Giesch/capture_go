defmodule CaptureGoWeb.LiveRedirect do
  import Phoenix.Controller, only: [redirect: 2]
  alias CaptureGoWeb.LiveLobby
  alias CaptureGoWeb.Router.Helpers, as: Routes

  # TODO: check if there are better route helpers for LiveView

  def lobby_redirect(conn) do
    redirect(conn, to: Routes.lobby_path(conn, LiveLobby))
  end
end
