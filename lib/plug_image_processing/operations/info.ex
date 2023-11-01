defmodule PlugImageProcessing.Operations.Info do
  defstruct image: nil

  alias Vix.Vips.Image

  def new(_image, _params, _config) do
    {:error, :invalid_operation}
  end

  defimpl PlugImageProcessing.Info do
    def process(operation) do
      {:ok,
       %PlugImageProcessing.ImageMetadata{
         channels: Image.bands(operation.image),
         has_alpha: Image.has_alpha?(operation.image),
         height: Image.height(operation.image),
         width: Image.width(operation.image)
       }}
    end
  end
end
