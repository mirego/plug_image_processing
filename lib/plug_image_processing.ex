defmodule PlugImageProcessing do
  alias PlugImageProcessing.Middleware
  alias PlugImageProcessing.Middlewares.SignatureKey
  alias PlugImageProcessing.Operation
  alias PlugImageProcessing.Source

  def generate_url(url, config, operation, query) do
    config = struct!(PlugImageProcessing.Config, config)

    uri = URI.parse(url)
    uri = %{uri | path: config.path <> "/#{operation}"}
    uri = %{uri | query: URI.encode_query(query)}

    uri =
      if Middleware.enabled?(%SignatureKey{config: config}, nil) do
        sign = SignatureKey.generate_signature(URI.to_string(uri), config)
        URI.append_query(uri, "sign=#{sign}")
      else
        uri
      end

    URI.to_string(uri)
  end

  def run_middlewares(conn, config) do
    Enum.reduce_while(config.middlewares, conn, fn module, conn ->
      middleware = struct!(module, config: config)

      with true <- Middleware.enabled?(middleware, conn),
           conn when not conn.halted <- Middleware.run(middleware, conn) do
        {:cont, conn}
      else
        conn when conn.halted -> {:halt, conn}
        _ -> {:cont, conn}
      end
    end)
  end

  def params_operations(image, params, config) do
    image =
      Enum.reduce_while(params, image, fn {key, value}, image ->
        case operations(image, key, %{key => value}, config) do
          {:ok, image} -> {:cont, image}
          {:error, :invalid_operation} -> {:cont, image}
          error -> {:halt, error}
        end
      end)

    case image do
      %Vix.Vips.Image{} = image -> {:ok, image}
      error -> error
    end
  end

  def operations(image, operation_name, params, config) do
    operation =
      Enum.find_value(config.operations, fn {name, module_name} ->
        operation_name === name && module_name.new(image, params)
      end) || {:error, :invalid_operation}

    with {:ok, operation} <- operation,
         true <- Operation.valid?(operation) do
      Operation.process(operation, config)
    end
  end

  def cast_operation_name(name, config) do
    if name in Enum.map(config.operations, &elem(&1, 0)) do
      {:ok, name}
    else
      {:error, :invalid_operation}
    end
  end

  def get_image(params, config) do
    source = Enum.find_value(config.sources, &Source.cast(struct(&1), params))

    if source do
      Source.get_image(source)
    else
      {:error, :unknown_source}
    end
  end

  def write_to_stream(image, file_extension) do
    Vix.Vips.Image.write_to_stream(image, ".#{file_extension}")
  end
end
