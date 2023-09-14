defmodule PlugImageProcessing do
  alias PlugImageProcessing.Info
  alias PlugImageProcessing.Middleware
  alias PlugImageProcessing.Middlewares.SignatureKey
  alias PlugImageProcessing.Operation
  alias PlugImageProcessing.Source

  @type image :: Vix.Vips.Image.t()
  @type config :: PlugImageProcessing.Config.t()
  @type image_metadata :: PlugImageProcessing.ImageMetadata.t()

  @spec generate_url(String.t(), Enumerable.t(), atom(), map()) :: String.t()
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

  @spec run_middlewares(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def run_middlewares(conn, config) do
    Enum.reduce_while(config.middlewares, conn, fn module, conn ->
      middleware = struct!(module, config: config)

      with true <- Middleware.enabled?(middleware, conn),
           conn when not conn.halted <- Middleware.run(middleware, conn) do
        {:cont, conn}
      else
        conn when is_struct(conn, Plug.Conn) and conn.halted -> {:halt, conn}
        _ -> {:cont, conn}
      end
    end)
  end

  @spec params_operations(image(), map(), config()) :: {:ok, image()} | {:error, atom()}
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

  @spec operations(image(), String.t(), map(), config()) :: {:ok, image()} | {:error, atom()}
  def operations(image, operation_name, params, config) do
    operation =
      Enum.find_value(config.operations, fn {name, module_name} ->
        operation_name === name && module_name.new(image, params, config)
      end) || {:error, :invalid_operation}

    with {:ok, operation} <- operation,
         true <- Operation.valid?(operation) do
      Operation.process(operation, config)
    end
  end

  @spec info(image()) :: {:ok, image_metadata()} | {:error, atom()}
  def info(image), do: Info.process(%PlugImageProcessing.Operations.Info{image: image})

  @spec cast_operation_name(String.t(), config()) :: {:ok, String.t()} | {:error, atom()}
  def cast_operation_name(name, config) do
    if name in Enum.map(config.operations, &elem(&1, 0)) do
      {:ok, name}
    else
      {:error, :invalid_operation}
    end
  end

  @spec get_image(map(), String.t(), config()) :: {:ok, image(), String.t() | nil, String.t()} | {:error, atom()}
  def get_image(params, operation_name, config) do
    source = Enum.find_value(config.sources, &Source.cast(struct(&1), params))

    if source do
      Source.get_image(source, operation_name, config)
    else
      {:error, :unknown_source}
    end
  end

  @spec write_to_buffer(image(), String.t()) :: {:ok, binary()} | {:error, term()}
  def write_to_buffer(image, file_extension) do
    Vix.Vips.Image.write_to_buffer(image, file_extension)
  end
end
