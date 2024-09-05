defmodule PlugImageProcessing.Operations.Info do
  @moduledoc false
  alias Vix.Vips.Image

  defstruct image: nil

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
