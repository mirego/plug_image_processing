defmodule PlugImageProcessing.Operations.Resize do
  @moduledoc false
  import PlugImageProcessing.Options

  alias Vix.Vips.Image

  defstruct image: nil, width: nil, height: nil

  def new(image, params, _config) do
    with {:ok, width} <- cast_integer(params["w"] || params["width"]),
         {:ok, height} <- cast_integer(params["h"] || params["height"]) do
      {:ok,
       struct!(__MODULE__, %{
         image: image,
         width: width,
         height: height
       })}
    end
  end

  defimpl PlugImageProcessing.Operation do
    def valid?(operation) do
      if operation.width do
        true
      else
        {:error, :missing_width}
      end
    end

    def process(operation, _config) do
      hscale = operation.width / Image.width(operation.image) * 1.0
      vscale = if operation.height, do: operation.height / Image.height(operation.image)

      options = PlugImageProcessing.Options.build(vscale: vscale)

      Vix.Vips.Operation.resize(operation.image, hscale, options)
    end
  end
end
