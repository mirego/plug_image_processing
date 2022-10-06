defmodule ImageProxy.ConnValidations.SignatureKey do
  defstruct config: nil

  defimpl ImageProxy.ConnValidation do
    require Logger

    import Plug.Conn

    def enabled?(validation, _conn), do: not is_nil(validation.config.signature_key)

    def validate(validation, conn) do
      key = validation.config.signature_key
      [_, url_path] = conn.path_info

      url_query =
        conn.params
        |> Enum.sort_by(fn {key, _} -> key end)
        |> Enum.reject(fn {key, _} -> key === "sign" end)
        |> Map.new()
        |> URI.encode_query()

      valid_sign = generate_signature(key, url_path <> url_query)

      if valid_sign === conn.params["sign"] do
        conn
      else
        Logger.error("[ImageProxy] - Invalid signature. Got: #{inspect(conn.params["sign"])}, expected: #{valid_sign}")

        conn
        |> send_resp(403, "invalid signature")
        |> halt()
      end
    end

    defp generate_signature(key, value) do
      Base.url_encode64(:crypto.mac(:hmac, :sha256, key, value))
    end
  end
end
