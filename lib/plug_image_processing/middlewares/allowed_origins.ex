defmodule PlugImageProcessing.Middlewares.AllowedOrigins do
  @moduledoc false
  defstruct config: nil

  defimpl PlugImageProcessing.Middleware do
    import Plug.Conn

    require Logger

    def enabled?(middleware, conn) do
      not is_nil(conn.params["url"]) and is_list(middleware.config.allowed_origins)
    end

    def run(middleware, conn) do
      origins = middleware.config.allowed_origins

      with url when not is_nil(url) <- conn.params["url"],
           url = URI.decode_www_form(url),
           uri when not is_nil(uri.host) <- URI.parse(url),
           true <- uri.host in origins do
        conn
      else
        _ ->
          Logger.error("[PlugImageProcessing] - Unallowed origins. Got: #{conn.params["url"]}, expected one of: #{inspect(origins)}")

          conn
          |> send_resp(:forbidden, "Forbidden: Unallowed origin")
          |> halt()
      end
    end
  end
end
