defmodule CaptureGo.System do
  use Supervisor

  def start_link(_ \\ nil) do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    Supervisor.init(
      [
        CaptureGo.GameRegistry,
        CaptureGo.GameSupervisor,
        CaptureGo.LobbyServer
      ],
      strategy: :rest_for_one
    )
  end
end
