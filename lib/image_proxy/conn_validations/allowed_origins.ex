defmodule ImageProxy.ConnValidations.AllowedOrigins do
  defstruct config: nil

  defimpl ImageProxy.ConnValidation do
    require Logger

    import Plug.Conn

    def enabled?(validation, conn) do
      not is_nil(conn.params["url"]) and not is_nil(validation.config.allowed_origins) and is_list(validation.config.allowed_origins)
    end

    def validate(validation, conn) do
      origins = validation.config.allowed_origins

      uri = URI.parse(conn.params["url"])

      if uri.host in origins do
        conn
      else
        Logger.error("[ImageProxy] - Unallowed origins. Got: #{inspect(uri.host)}, expected one of: #{inspect(origins)}")

        conn
        |> send_resp(403, "unallowed origin")
        |> halt()
      end
    end
  end
end
