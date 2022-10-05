defmodule ImageProxy.Operations.Crop do
  defstruct image: nil, left: 0, top: 0, width: nil, height: nil, gravity: nil

  import ImageProxy.Options

  def new(image, params) do
    with {:ok, width} <- cast_integer(params["width"]),
         {:ok, left} <- cast_integer(params["left"], 0),
         {:ok, top} <- cast_integer(params["top"], 0),
         {:ok, height} <- cast_integer(params["height"]) do
      {:ok,
       struct!(__MODULE__, %{
         image: image,
         gravity: params["gravity"],
         top: top,
         left: left,
         width: width,
         height: height
       })}
    end
  end

  defimpl ImageProxy.Operation do
    def valid?(operation) do
      if operation.width && operation.height && operation.top && operation.left do
        true
      else
        {:error, :missing_arguments}
      end
    end

    def process(operation = %{gravity: "smart"}) do
      Vix.Vips.Operation.smartcrop(operation.image, operation.width, operation.height)
    end

    def process(operation) do
      Vix.Vips.Operation.extract_area(
        operation.image,
        operation.left,
        operation.top,
        operation.width,
        operation.height
      )
    end
  end
end
