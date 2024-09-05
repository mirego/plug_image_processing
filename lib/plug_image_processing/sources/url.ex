defmodule PlugImageProcessing.Sources.URL do
  @moduledoc false
  alias PlugImageProcessing.Options

  defstruct uri: nil, params: nil

  @type t :: %__MODULE__{}

  @types_extensions_mapping %{
    "jpg" => ".jpg",
    "jpeg" => ".jpg",
    "png" => ".png",
    "webp" => ".webp",
    "gif" => ".gif",
    "svg" => ".svg",
    "svg+xml" => ".svg"
  }

  @valid_types Map.keys(@types_extensions_mapping)
  @valid_extensions Map.values(@types_extensions_mapping)
  @extensions_types_mapping Map.new(@types_extensions_mapping, fn {k, v} -> {v, k} end)

  def fetch_body(source, http_client_timeout, http_client_max_length, http_client, http_client_cache) do
    metadata = %{uri: source.uri}
    url = URI.to_string(source.uri)

    response =
      cond do
        http_client_cache.invalid_source?(source) ->
          :telemetry.execute(
            [:plug_image_processing, :source, :url, :invalid_source],
            metadata
          )

          {:cached_error, url}

        response = http_client_cache.fetch_source(source) ->
          :telemetry.execute(
            [:plug_image_processing, :source, :url, :cached_source],
            metadata
          )

          response

        true ->
          http_get_task = Task.async(fn -> http_client.get(url, http_client_max_length) end)

          case Task.yield(http_get_task, http_client_timeout) || Task.shutdown(http_get_task) do
            nil ->
              {:http_timeout, "Timeout (#{http_client_timeout}ms) on #{url}"}

            {:exit, reason} ->
              {:http_exit, "Exit with #{reason} (#{http_client_timeout}ms) on #{url}"}

            {:ok, result} ->
              http_client_cache.put_source(source, result)
              result
          end
      end

    with {:ok, body, headers} <- response do
      content_type =
        case List.keyfind(headers, "Content-Type", 0) do
          {_, value} -> value
          _ -> ""
        end

      case get_file_suffix(source, content_type) do
        {:invalid_file_type, type} ->
          {:file_type_error, "Invalid file type: #{type}"}

        {content_type, file_suffix} ->
          {:ok, body, content_type, file_suffix}
      end
    end
  end

  defp get_file_suffix_from_http_header(content_type) do
    content_type = String.trim_leading(content_type, "image/")

    if content_type in @valid_types do
      content_type
    end
  end

  defp get_file_suffix_from_query_params(params) do
    if params["type"] in @valid_types do
      params["type"]
    end
  end

  defp get_file_suffix_from_uri(uri) do
    case uri.path && Path.extname(uri.path) do
      "." <> content_type -> content_type
      _ -> nil
    end
  end

  defp get_file_suffix(source, content_type) do
    image_type = get_file_suffix_from_query_params(source.params)
    # If "type" query param is not found or is invalid, fallback to HTTP header
    image_type = image_type || get_file_suffix_from_http_header(content_type)
    # If HTTP header "Content-Type" is not found or is invalid, fallback to source uri
    image_type = image_type || get_file_suffix_from_uri(source.uri)

    type = Map.get(@types_extensions_mapping, image_type)

    case type do
      ".gif" ->
        options =
          [{"strip", Options.cast_boolean(source.params["stripmeta"])}]
          |> Options.build()
          |> Options.encode_suffix()

        {"image/gif", type <> options}

      # Since libvips can read SVG format but not serve it, we just convert the SVG into a PNG.
      ".svg" ->
        options =
          [{"strip", Options.cast_boolean(source.params["stripmeta"])}]
          |> Options.build()
          |> Options.encode_suffix()

        {"image/png", ".png" <> options}

      extension_name when extension_name in @valid_extensions ->
        content_type = Map.get(@extensions_types_mapping, extension_name)

        if content_type do
          options =
            [
              {"Q", Options.cast_integer(source.params["quality"])},
              {"strip", Options.cast_boolean(source.params["stripmeta"])}
            ]
            |> Options.build()
            |> Options.encode_suffix()

          {"image/#{content_type}", type <> options}
        else
          {:invalid_file_type, extension_name}
        end

      _ ->
        {:invalid_file_type, image_type}
    end
  end

  defimpl PlugImageProcessing.Source do
    alias PlugImageProcessing.Sources.URL

    require Logger

    def get_image(source, operation_name, config) do
      with :ok <- maybe_redirect(source, operation_name, config),
           {:ok, body, content_type, file_suffix} when is_binary(file_suffix) and is_binary(body) <- fetch_remote_image(source, config),
           {:ok, image} <- Vix.Vips.Image.new_from_buffer(body, buffer_options(content_type)) do
        {:ok, image, content_type, file_suffix}
      else
        {:http_timeout, message} ->
          Logger.error("[PlugImageProcessing] - Timeout while fetching source URL: #{message}")
          {:error, :timeout}

        {:error, message} ->
          Logger.error("[PlugImageProcessing] - Error while fetching source URL: #{message}")
          {:error, :invalid_file}

        {:cached_error, url} ->
          Logger.error("[PlugImageProcessing] - Cached error on #{url}")
          {:error, :invalid_file}

        {:file_type_error, message} ->
          Logger.error("[PlugImageProcessing] - File type error while fetching source URL. Got #{message} on #{source.uri}")
          {:error, :invalid_file_type}

        {:http_error, status} ->
          Logger.error("[PlugImageProcessing] - HTTP error while fetching source URL. Got #{status} on #{source.uri}")
          {:error, :invalid_file}

        {:redirect, url} ->
          {:redirect, url}

        error ->
          Logger.error("[PlugImageProcessing] - Unable to fetch source URL: #{inspect(error)}")
          {:error, :invalid_file}
      end
    end

    defp maybe_redirect(source, operation_name, config) do
      if operation_name in config.source_url_redirect_operations do
        {:redirect, to_string(source.uri)}
      else
        :ok
      end
    end

    defp buffer_options("image/gif"), do: [n: -1]
    defp buffer_options(_), do: []

    defp fetch_remote_image(source, config) do
      metadata = %{uri: source.uri}

      :telemetry.span(
        [:plug_image_processing, :source, :url, :request],
        metadata,
        fn ->
          result = URL.fetch_body(source, config.http_client_timeout, config.http_client_max_length, config.http_client, config.http_client_cache)
          {result, %{}}
        end
      )
    end

    def cast(source, params) do
      with url when not is_nil(url) <- params["url"],
           url = URI.decode_www_form(url),
           uri when not is_nil(uri.host) <- URI.parse(url) do
        struct!(source, uri: uri, params: params)
      else
        _ -> false
      end
    end
  end
end
