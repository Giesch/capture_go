defmodule CaptureGo.GameSupervisor do
  alias CaptureGo.GameServer

  def start_link() do
    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  def start_game(game_id, host_token, password \\ nil) do
    options = [game_id: game_id, host_token: host_token, password: password]

    case start_child(options) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(options) do
    DynamicSupervisor.start_child(__MODULE__, {GameServer, options})
  end

  def stop_game(game_server) do
    DynamicSupervisor.terminate_child(__MODULE__, game_server)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end
end
