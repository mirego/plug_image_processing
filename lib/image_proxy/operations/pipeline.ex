defmodule ImageProxy.Operations.Pipeline do
  defstruct image: nil, operations: nil

  import ImageProxy.Options

  def new(image, params) do
    with {:ok, operations} <- cast_json(params["operations"]) do
      {:ok,
       struct!(__MODULE__, %{
         image: image,
         operations: operations
       })}
    end
  end

  defimpl ImageProxy.Operation do
    def valid?(operation) do
      if Enum.any?(operation.operations) do
        true
      else
        {:error, :invalid_operations}
      end
    end

    def process(operation) do
      Enum.reduce_while(operation.operations, operation.image, fn operation, image ->
        operation_name = operation["operation"]
        params = operation["params"]

        case ImageProxy.operations(image, operation_name, params) do
          {:ok, image} -> {:cont, image}
          error -> {:halt, error}
        end
      end)
      |> case do
        %Vix.Vips.Image{} = image -> {:ok, image}
        error -> error
      end
    end
  end
end
