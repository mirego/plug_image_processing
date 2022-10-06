defmodule ImageProxy do
  alias ImageProxy.ConnValidation
  alias ImageProxy.ConnValidations
  alias ImageProxy.Operation
  alias ImageProxy.Operations
  alias ImageProxy.Source
  alias ImageProxy.Sources

  @sources [
    Sources.URL
  ]

  @operations [
    {"crop", Operations.Crop},
    {"flip", Operations.Flip},
    {"watermarkimage", Operations.WatermarkImage},
    {"extract", Operations.ExtractArea},
    {"resize", Operations.Resize},
    {"smartcrop", Operations.Smartcrop},
    {"pipeline", Operations.Pipeline}
  ]

  @conn_validations [
    ConnValidations.SignatureKey,
    ConnValidations.AllowedOrigins
  ]

  def validate_conn(conn, config) do
    Enum.reduce_while(@conn_validations, conn, fn module, conn ->
      validation = struct!(module, config: config)

      with true <- ConnValidation.enabled?(validation, conn),
           conn when not conn.halted <- ConnValidation.validate(validation, conn) do
        {:cont, conn}
      else
        conn when conn.halted -> {:halt, conn}
        _ -> {:cont, conn}
      end
    end)
  end

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
         true <- Operation.valid?(operation) do
      Operation.process(operation)
    end
  end

  for {name, _module_name} <- @operations do
    def cast_operation_name(unquote(name)), do: {:ok, unquote(name)}
  end

  def cast_operation_name(_), do: {:error, :invalid_operation}

  def get_image(params) do
    source = Enum.find_value(@sources, &Source.cast(struct(&1), params))

    if source do
      Source.get_image(source)
    else
      {:error, :unknown_source}
    end
  end

  def write_to_stream(image, file_extension) do
    Vix.Vips.Image.write_to_stream(image, ".#{file_extension}")
  end

  for {name, module_name} <- @operations do
    defp operation_struct(unquote(name), image, params) do
      unquote(module_name).new(image, params)
    end
  end

  defp operation_struct(_, _image, _params), do: {:error, :invalid_operation}
end
