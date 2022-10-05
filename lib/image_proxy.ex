defmodule ImageProxy do
  @sources [
    ImageProxy.Sources.URL
  ]

  @operations [
    {"crop", ImageProxy.Operations.Crop},
    {"flip", ImageProxy.Operations.Flip},
    {"watermarkimage", ImageProxy.Operations.WatermarkImage},
    {"extract", ImageProxy.Operations.ExtractArea},
    {"resize", ImageProxy.Operations.Resize},
    {"smartcrop", ImageProxy.Operations.Smartcrop},
    {"pipeline", ImageProxy.Operations.Pipeline}
  ]

  def params_operations(image, params) do
    params
    |> Enum.reduce_while(image, fn {key, value}, image ->
      case operations(image, key, %{key => value}) do
        {:ok, image} -> {:cont, image}
        {:error, :invalid_operation} -> {:cont, image}
        error -> {:halt, error}
      end
    end)
    |> case do
      %Vix.Vips.Image{} = image -> {:ok, image}
      error -> error
    end
  end

  def operations(image, operation_name, params) do
    with {:ok, operation} <- operation_struct(operation_name, image, params),
         true <- ImageProxy.Operation.valid?(operation) do
      ImageProxy.Operation.process(operation)
    end
  end

  for {name, _module_name} <- @operations do
    def cast_operation_name(unquote(name)), do: {:ok, unquote(name)}
  end

  def cast_operation_name(_), do: {:error, :invalid_operation}

  for {name, module_name} <- @operations do
    defp operation_struct(unquote(name), image, params) do
      unquote(module_name).new(image, params)
    end
  end

  defp operation_struct(_, _image, _params), do: {:error, :invalid_operation}

  def get_image(params) do
    source = Enum.find_value(@sources, &ImageProxy.Source.cast(struct(&1), params))
    ImageProxy.Source.get_image(source)
  end

  def write_to_stream(image, file_extension) do
    Vix.Vips.Image.write_to_stream(image, ".#{file_extension}")
  end
end
