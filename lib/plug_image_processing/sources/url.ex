defmodule PlugImageProcessing.Sources.URL do
  defstruct uri: nil, params: nil

  @type t :: %__MODULE__{}

  alias PlugImageProcessing.Options

  @valid_types ~w(jpg jpeg png webp gif)

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

      {content_type, file_suffix} = get_file_suffix(source, content_type)

      {:ok, body, content_type, file_suffix}
    end
  end

  defp get_file_suffix(source, content_type) do
    # Find the type in the source response content-type header
    type = String.trim_leading(content_type, "image/")

    type =
      if type in @valid_types do
        "." <> type
      else
        nil
      end

    # Find the type in the client provided "type" query param
    type =
      if source.params["type"] in @valid_types do
        "." <> source.params["type"]
      else
        type
      end

    # Fallback to the extension name of the "url" query param
    type = type || (source.uri.path && Path.extname(source.uri.path))

    case type do
      ".gif" ->
        options =
          [{"strip", Options.cast_boolean(source.params["stripmeta"])}]
          |> Options.build()
          |> Options.encode_suffix()

        {"image/gif", type <> options}

      "." <> type_name ->
        options =
          [
            {"Q", Options.cast_integer(source.params["quality"])},
            {"strip", Options.cast_boolean(source.params["stripmeta"])}
          ]
          |> Options.build()
          |> Options.encode_suffix()

        {"image/#{type_name}", type <> options}

      _ ->
        :invalid_file_type
    end
  end

  defimpl PlugImageProcessing.Source do
    require Logger

    alias PlugImageProcessing.Sources.URL

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
