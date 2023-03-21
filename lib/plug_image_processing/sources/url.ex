defmodule PlugImageProcessing.Sources.URL do
  defstruct uri: nil, params: nil

  alias PlugImageProcessing.Options

  @valid_types ~w(jpg jpeg png webp gif)

  def fetch_body(source, http_client) do
    url = URI.to_string(source.uri)
    Logger.metadata(plug_image_processing_source_url: url)

    with {:ok, body, headers} <- http_client.get(url) do
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

    def get_image(source, config) do
      with {:ok, body, content_type, file_suffix} when is_binary(file_suffix) and is_binary(body) <- fetch_remote_image(source, config.http_client),
           {:ok, image} <- Vix.Vips.Image.new_from_buffer(body, buffer_options(content_type)) do
        {:ok, image, content_type, file_suffix}
      else
        error ->
          Logger.error("[PlugImageProcessing] - Unable to fetch source URL. #{inspect(error)}")
          {:error, :invalid_file}
      end
    end

    defp buffer_options("image/gif"), do: [n: -1]
    defp buffer_options(_), do: []

    defp fetch_remote_image(source, http_client) do
      metadata = %{uri: source.uri}

      :telemetry.span(
        [:plug_image_processing, :source, :url, :request],
        metadata,
        fn ->
          result = URL.fetch_body(source, http_client)
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
