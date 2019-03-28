defmodule CaptureGoWeb.PageController do
  use CaptureGoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
