defmodule PlugImageProcessing.Operations.WatermarkImage do
  defstruct image: nil, sub: nil, left: nil, top: nil, right: nil, bottom: nil, http_client: nil

  import PlugImageProcessing.Options

  def new(image, params, config) do
    with {:ok, sub} <- cast_remote_image(params["image"], config),
         {:ok, left} <- cast_integer(params["left"]),
         {:ok, right} <- cast_integer(params["right"]),
         {:ok, bottom} <- cast_integer(params["bottom"]),
         {:ok, top} <- cast_integer(params["top"]) do
      {:ok,
       struct!(__MODULE__, %{
         image: image,
         sub: sub,
         left: left,
         right: right,
         top: top,
         bottom: bottom
       })}
    end
  end

  defimpl PlugImageProcessing.Operation do
    alias Vix.Vips.Image

    def valid?(operation) do
      if operation.sub do
        true
      else
        {:error, :missing_image}
      end
    end

    def process(operation, _config) do
      x = if operation.left, do: operation.left
      x = if operation.right, do: Image.width(operation.image) - Image.width(operation.sub) - operation.right, else: x
      x = x || 0

      y = if operation.top, do: operation.top
      y = if operation.bottom, do: Image.height(operation.image) - Image.height(operation.sub) - operation.bottom, else: y
      y = y || 0

      Vix.Vips.Operation.composite([operation.image, operation.sub], [:VIPS_BLEND_MODE_OVER], x: [x], y: [y])
    end
  end
end
