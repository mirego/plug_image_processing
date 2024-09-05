defmodule PlugImageProcessing.Operations.Smartcrop do
  @moduledoc false
  import PlugImageProcessing.Options

  def new(image, params, _config) do
    with {:ok, width} <- cast_integer(params["width"]),
         {:ok, height} <- cast_integer(params["height"]) do
      {:ok,
       struct!(PlugImageProcessing.Operations.Crop, %{
         image: image,
         gravity: "smart",
         width: width,
         height: height
       })}
    end
  end
end
