defmodule CaptureGoWeb.LobbyView do
  use CaptureGoWeb, :view

  # a toggle for the bulma css class
  def is_active(active) do
    if active do
      "is-active"
    else
      ""
    end
  end
end
