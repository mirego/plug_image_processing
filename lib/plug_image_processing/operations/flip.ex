defmodule PlugImageProcessing.Operations.Flip do
  @moduledoc false
  import PlugImageProcessing.Options

  defstruct image: nil, direction: nil

  def new(image, params, _config) do
    with {:ok, direction} <- cast_direction(params["flip"], :VIPS_DIRECTION_HORIZONTAL),
         {:ok, direction} <- cast_direction(params["direction"], direction),
         {:ok, direction} <- cast_boolean(params["flip"], direction) do
      {:ok,
       struct!(__MODULE__, %{
         image: image,
         direction: direction
       })}
    end
  end

  defimpl PlugImageProcessing.Operation do
    def valid?(_operation) do
      true
    end

    def process(operation, _config) do
      direction = if is_boolean(operation.direction), do: :VIPS_DIRECTION_HORIZONTAL, else: operation.direction

      Vix.Vips.Operation.flip(operation.image, direction)
    end
  end
end
