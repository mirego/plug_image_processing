defmodule PlugImageProcessing.Middlewares.CacheHeadersTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Middlewares.CacheHeaders

  describe "enabled?" do
    test "returns true when http_cache_ttl is an integer" do
      config = %Config{path: "/imageproxy", http_cache_ttl: 3600}
      middleware = %CacheHeaders{config: config}
      conn = conn(:get, "/imageproxy/resize")

      assert PlugImageProcessing.Middleware.enabled?(middleware, conn)
    end

    test "returns false when http_cache_ttl is nil" do
      config = %Config{path: "/imageproxy", http_cache_ttl: nil}
      middleware = %CacheHeaders{config: config}
      conn = conn(:get, "/imageproxy/resize")

      refute PlugImageProcessing.Middleware.enabled?(middleware, conn)
    end

    test "returns false when http_cache_ttl is not an integer" do
      config = %Config{path: "/imageproxy", http_cache_ttl: "3600"}
      middleware = %CacheHeaders{config: config}
      conn = conn(:get, "/imageproxy/resize")

      refute PlugImageProcessing.Middleware.enabled?(middleware, conn)
    end
  end

  describe "run" do
    test "sets cache-control header with positive TTL" do
      config = %Config{path: "/imageproxy", http_cache_ttl: 3600}
      middleware = %CacheHeaders{config: config}
      conn = conn(:get, "/imageproxy/resize")

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert get_resp_header(result_conn, "cache-control") == ["public, s-maxage=3600, max-age=3600, no-transform"]
    end

    test "sets no-cache header when TTL is 0" do
      config = %Config{path: "/imageproxy", http_cache_ttl: 0}
      middleware = %CacheHeaders{config: config}
      conn = conn(:get, "/imageproxy/resize")

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert get_resp_header(result_conn, "cache-control") == ["private, no-cache, no-store, must-revalidate"]
    end

    test "sets cache-control header with different TTL values" do
      test_cases = [
        {1800, "public, s-maxage=1800, max-age=1800, no-transform"},
        {7200, "public, s-maxage=7200, max-age=7200, no-transform"},
        {86_400, "public, s-maxage=86400, max-age=86400, no-transform"}
      ]

      for {ttl, expected_header} <- test_cases do
        config = %Config{path: "/imageproxy", http_cache_ttl: ttl}
        middleware = %CacheHeaders{config: config}
        conn = conn(:get, "/imageproxy/resize")

        result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

        assert get_resp_header(result_conn, "cache-control") == [expected_header]
      end
    end
  end

  describe "cache_control/1" do
    test "returns no-cache directive for TTL 0" do
      assert PlugImageProcessing.Middleware.PlugImageProcessing.Middlewares.CacheHeaders.cache_control(0) ==
               "private, no-cache, no-store, must-revalidate"
    end

    test "returns public cache directive for positive TTL" do
      assert PlugImageProcessing.Middleware.PlugImageProcessing.Middlewares.CacheHeaders.cache_control(3600) ==
               "public, s-maxage=3600, max-age=3600, no-transform"
    end

    test "returns correct cache directive for various TTL values" do
      test_cases = [
        {1, "public, s-maxage=1, max-age=1, no-transform"},
        {60, "public, s-maxage=60, max-age=60, no-transform"},
        {3600, "public, s-maxage=3600, max-age=3600, no-transform"},
        {86_400, "public, s-maxage=86400, max-age=86400, no-transform"}
      ]

      for {ttl, expected} <- test_cases do
        assert PlugImageProcessing.Middleware.PlugImageProcessing.Middlewares.CacheHeaders.cache_control(ttl) == expected
      end
    end
  end
end
