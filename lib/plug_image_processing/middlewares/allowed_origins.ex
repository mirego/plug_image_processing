defmodule PlugImageProcessing.Middlewares.AllowedOrigins do
  @moduledoc """
  Middleware for validating that image URLs come from allowed origins.

  This middleware provides security by restricting which domains can be used
  as image sources. It validates the host of the provided URL against a
  configured allowlist of origins.

  ## Configuration

  Set `allowed_origins` in your config to enable this middleware:

      plug PlugImageProcessing.Web, allowed_origins: ["example.com", "cdn.example.com"]

  ## Security

  - Uses exact host matching to prevent subdomain bypass attacks
  - Safely handles malformed URLs without crashing
  - Returns 403 Forbidden for unauthorized origins
  """
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
           {:ok, decoded_url} <- safe_decode_url(url),
           uri when not is_nil(uri.host) <- URI.parse(decoded_url),
           true <- Enum.member?(origins, uri.host) do
        conn
      else
        _ ->
          Logger.error("[PlugImageProcessing] - Unallowed origins. Expected one of: #{inspect(origins)}")

          conn
          |> send_resp(:forbidden, "Forbidden: Unallowed origin")
          |> halt()
      end
    end

    defp safe_decode_url(url) do
      {:ok, URI.decode_www_form(url)}
    rescue
      _ -> {:error, :invalid_url}
    end
  end
end
