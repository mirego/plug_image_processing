defmodule ImageProxy.Operations.Smartcrop do
  import ImageProxy.Options

  def new(image, params) do
    with {:ok, width} <- cast_integer(params["width"]),
         {:ok, height} <- cast_integer(params["height"]) do
      {:ok,
       struct!(ImageProxy.Operations.Crop, %{
         image: image,
         gravity: "smart",
         width: width,
         height: height
       })}
    end
  end
end
