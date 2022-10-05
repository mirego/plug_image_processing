defmodule ImageProxy.Operations.Flip do
  defstruct image: nil, direction: nil

  import ImageProxy.Options

  def new(image, params) do
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

  defimpl ImageProxy.Operation do
    def valid?(_operation) do
      true
    end

    def process(operation) do
      direction = if is_boolean(operation.direction), do: :VIPS_DIRECTION_HORIZONTAL, else: operation.direction

      Vix.Vips.Operation.flip(operation.image, direction)
    end
  end
end
