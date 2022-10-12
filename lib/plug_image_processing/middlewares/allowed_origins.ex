defmodule PlugImageProcessing.Middlewares.AllowedOrigins do
  defstruct config: nil

  defimpl PlugImageProcessing.Middleware do
    require Logger

    import Plug.Conn

    def enabled?(middleware, conn) do
      not is_nil(conn.params["url"]) and is_list(middleware.config.allowed_origins)
    end

    def run(middleware, conn) do
      origins = middleware.config.allowed_origins

      uri = URI.parse(conn.params["url"])

      if uri.host in origins do
        conn
      else
        Logger.error("[PlugImageProcessing] - Unallowed origins. Got: #{inspect(uri.host)}, expected one of: #{inspect(origins)}")

        conn
        |> send_resp(403, "unallowed origin")
        |> halt()
      end
    end
  end
end
