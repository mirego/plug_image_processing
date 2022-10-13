defmodule PlugImageProcessing.Sources.URL do
  defstruct uri: nil, suffix: nil

  def fetch_body(uri) do
    url = URI.to_string(uri)
    Logger.metadata(plug_image_processing_source_url: url)

    :get
    |> Finch.build(url)
    |> Finch.request(__MODULE__)
    |> case do
      {:ok, response} when response.status === 200 and is_binary(response.body) ->
        {:ok, response.body}

      {:ok, error} ->
        {:error, error}

      {:error, error} ->
        {:error, error}

      error ->
        {:error, error}
    end
  end

  defimpl PlugImageProcessing.Source do
    require Logger

    alias PlugImageProcessing.Options

    @valid_types ~w(jpg jpeg png webp gif)

    def get_image(source) do
      metadata = %{uri: source.uri}

      body =
        :telemetry.span(
          [:plug_image_processing, :source, :url, :request],
          metadata,
          fn ->
            body = PlugImageProcessing.Sources.URL.fetch_body(source.uri)
            {body, %{}}
          end
        )

      with {:ok, body} <- body,
           {:ok, image} <- Vix.Vips.Image.new_from_buffer(body) do
        {:ok, image, source.suffix}
      else
        error ->
          Logger.error("[PlugImageProcessing] - Unable to fetch source URL. #{inspect(error)}")
          {:error, :invalid_file}
      end
    end

    defp get_file_suffix(params, uri) do
      type =
        if params["type"] in @valid_types do
          "." <> params["type"]
        else
          Path.extname(uri.path)
        end

      options =
        [
          {"Q", Options.cast_integer(params["quality"])},
          {"strip", Options.cast_boolean(params["stripmeta"])}
        ]
        |> Options.build()
        |> Options.encode_suffix()

      type <> options
    end

    def cast(source, params) do
      with url when not is_nil(url) <- params["url"],
           url = URI.decode_www_form(url),
           uri when not is_nil(uri.host) <- URI.parse(url) do
        suffix = get_file_suffix(params, uri)
        struct!(source, uri: uri, suffix: suffix)
      else
        _ -> false
      end
    end
  end
end
