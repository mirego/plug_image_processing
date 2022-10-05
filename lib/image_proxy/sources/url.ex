defmodule ImageProxy.Sources.URL do
  defstruct uri: nil, suffix: nil

  def fetch_body(uri) do
    Tesla.get!(URI.to_string(uri)).body
  end

  defimpl ImageProxy.Source do
    @valid_types ~w(jpg png webp gif)

    alias ImageProxy.Options

    def get_image(source) do
      metadata = %{uri: source.uri}

      body =
        :telemetry.span(
          [:image_proxy, :source, :url, :request],
          metadata,
          fn ->
            body = ImageProxy.Sources.URL.fetch_body(source.uri)
            {body, %{}}
          end
        )

      case Vix.Vips.Image.new_from_buffer(body) do
        {:ok, image} -> {:ok, image, source.suffix}
        _ -> {:error, :invalid_file}
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
           uri when not is_nil(uri.host) <- URI.parse(url) do
        suffix = get_file_suffix(params, uri)
        struct!(source, uri: uri, suffix: suffix)
      else
        _ -> false
      end
    end
  end
end
