defmodule ImageProxy.Operations.Resize do
  defstruct image: nil, width: nil, height: nil

  import ImageProxy.Options

  def new(image, params) do
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

  defimpl ImageProxy.Operation do
    def valid?(operation) do
      if operation.width do
        true
      else
        {:error, :missing_width}
      end
    end

    def process(operation) do
      hscale = operation.width / Vix.Vips.Image.width(operation.image)
      vscale = if operation.height, do: operation.height / Vix.Vips.Image.height(operation.image)

      options = ImageProxy.Options.build(vscale: vscale)

      Vix.Vips.Operation.resize(operation.image, hscale, options)
    end
  end
end
