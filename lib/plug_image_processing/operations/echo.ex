defmodule PlugImageProcessing.Operations.Echo do
  defstruct image: nil

  def new(image, _params, _config) do
    {:ok, struct!(__MODULE__, %{image: image})}
  end

  defimpl PlugImageProcessing.Operation do
    def valid?(_operation) do
      true
    end

    def process(operation, _config) do
      {:ok, operation.image}
    end
  end
end
