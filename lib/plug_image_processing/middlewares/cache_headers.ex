defmodule PlugImageProcessing.Middlewares.CacheHeaders do
  @moduledoc false
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

    def cache_control(0), do: "private, no-cache, no-store, must-revalidate"

    def cache_control(ttl) do
      "public, s-maxage=#{ttl}, max-age=#{ttl}, no-transform"
    end
  end
end
