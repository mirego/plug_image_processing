defmodule PlugImageProcessing.Middlewares.SignatureKey do
  defstruct config: nil

  def generate_signature(url, config) do
    uri = URI.parse(url)
    url_path = uri.path
    url_path = String.trim_leading(url_path, config.path <> "/")

    url_query =
      uri.query
      |> URI.decode_query()
      |> Enum.sort_by(fn {key, _} -> key end)
      |> Map.new()
      |> Map.drop(["sign"])
      |> URI.encode_query()

    Base.url_encode64(:crypto.mac(:hmac, :sha256, config.url_signature_key, url_path <> url_query))
  end

  defimpl PlugImageProcessing.Middleware do
    require Logger

    import Plug.Conn

    def enabled?(middleware, _conn), do: is_binary(middleware.config.url_signature_key)

    def run(middleware, conn) do
      valid_sign =
        PlugImageProcessing.Middlewares.SignatureKey.generate_signature(
          conn.request_path <> "?" <> conn.query_string,
          middleware.config
        )

      if valid_sign === conn.params["sign"] do
        conn
      else
        Logger.error("[PlugImageProcessing] - Invalid signature. Got: #{inspect(conn.params["sign"])}, expected: #{valid_sign}")

        conn
        |> send_resp(:unauthorized, "Unauthorized: Invalid signature")
        |> halt()
      end
    end
  end
end
