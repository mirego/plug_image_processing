defmodule PlugImageProcessing.Operations.Pipeline do
  @moduledoc false
  import PlugImageProcessing.Options

  defstruct image: nil, operations: nil

  def new(image, params, _config) do
    with {:ok, operations} <- cast_json(params["operations"]) do
      {:ok,
       struct!(__MODULE__, %{
         image: image,
         operations: operations
       })}
    end
  end

  defimpl PlugImageProcessing.Operation do
    def valid?(operation) do
      if Enum.any?(operation.operations) do
        true
      else
        {:error, :invalid_operations}
      end
    end

    def process(operation, config) do
      image =
        Enum.reduce_while(operation.operations, operation.image, fn operation, image ->
          operation_name = operation["operation"]
          params = operation["params"]

          case PlugImageProcessing.operations(image, operation_name, params, config) do
            {:ok, image} -> {:cont, image}
            error -> {:halt, error}
          end
        end)

      case image do
        %Vix.Vips.Image{} = image -> {:ok, image}
        error -> error
      end
    end
  end
end
