defmodule PlugImageProcessing.Operations.ExtractArea do
  import PlugImageProcessing.Options

  def new(image, params) do
    with {:ok, width} <- cast_integer(params["width"]),
         {:ok, left} <- cast_integer(params["left"], 0),
         {:ok, top} <- cast_integer(params["top"], 0),
         {:ok, height} <- cast_integer(params["height"]) do
      {:ok,
       struct!(PlugImageProcessing.Operations.Crop, %{
         image: image,
         top: top,
         left: left,
         width: width,
         height: height
       })}
    end
  end
end
