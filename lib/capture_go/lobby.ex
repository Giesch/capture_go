defmodule CaptureGo.Lobby do
  @moduledoc """
  A data type for managing tables
  """

  # should these be lists? maps? what key?
  # is it better to just do the filter/split when clients ask?
  defstruct open_tables: nil,
            active_tables: nil

  # necessary operations
  # new table
  # join/challenge table
  # remove all inactive tables

  # lobby can be a singleton named registered process,
  # that delegates to worker processes if necessary
  # name it the module name

  # map of what to what?
  # game name to pid?
  # generate game ids?
end
