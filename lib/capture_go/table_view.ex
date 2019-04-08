defmodule CaptureGo.TableView do
  @moduledoc """
  A struct for the public values of a Table
  """

  alias CaptureGo.Table
  alias CaptureGo.TableView

  defstruct state: nil,
            goban: nil

  def new(%Table{state: state, goban: goban}) do
    %TableView{state: state, goban: goban}
  end
end
