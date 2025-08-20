defmodule PlugImageProcessing.Middlewares.CacheHeaders do
  @moduledoc """
  Middleware for setting HTTP cache control headers on image responses.

  This middleware manages client and CDN caching behavior for processed images,
  helping to reduce server load and improve performance by leveraging browser
  and CDN caches.

  ## Configuration

  Set `http_cache_ttl` in your config to enable this middleware:

      # Cache images for 1 hour (3600 seconds)
      plug PlugImageProcessing.Web, http_cache_ttl: 3600

      # Disable caching
      plug PlugImageProcessing.Web, http_cache_ttl: 0

  ## Cache Behavior

  - TTL > 0: Sets public caching with the specified max-age
  - TTL = 0: Disables caching with no-cache, no-store directives
  - Includes s-maxage for shared cache (CDN) control
  - Sets no-transform to prevent CDN image modifications
  """
  defstruct config: nil

  defimpl PlugImageProcessing.Middleware do
    import Plug.Conn

    def enabled?(middleware, _conn) do
      is_integer(middleware.config.http_cache_ttl)
    end

    def run(middleware, conn) do
      ttl = middleware.config.http_cache_ttl

      put_resp_header(conn, "cache-control", cache_control(ttl))
    end

    defp cache_control(0), do: "private, no-cache, no-store, must-revalidate"

    defp cache_control(ttl) do
      "public, s-maxage=#{ttl}, max-age=#{ttl}, no-transform"
    end
  end
end
