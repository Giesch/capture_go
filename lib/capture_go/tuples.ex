defmodule CaptureGo.Tuples do
  @moduledoc """
  Ok/Error tuple utils
  """

  def map_ok(tuple, fun)

  def map_ok({:ok, val}, fun)
      when is_function(fun, 1) do
    {:ok, fun.(val)}
  end

  def map_ok({:error, _reason} = failure, fun)
      when is_function(fun, 1) do
    failure
  end

  ###########

  def and_then(tuple, fun)

  def and_then({:ok, val}, fun)
      when is_function(fun, 1) do
    fun.(val)
  end

  def and_then({:error, _reason} = failure, fun)
      when is_function(fun, 1) do
    failure
  end

  ###########

  def map_err(tuple, fun)

  def map_err({:ok, _val} = success, fun)
      when is_function(fun, 1) do
    success
  end

  def map_err({:error, reason}, fun)
      when is_function(fun, 1) do
    {:error, fun.(reason)}
  end

  ###########

  def put_err(tuple, reason)

  def put_err({:ok, _val} = success, _reason) do
    success
  end

  def put_err({:error, _orig}, reason) do
    {:error, reason}
  end
end
