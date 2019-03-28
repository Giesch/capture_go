defmodule CaptureGo.Repo do
  use Ecto.Repo,
    otp_app: :capture_go,
    adapter: Ecto.Adapters.Postgres
end
