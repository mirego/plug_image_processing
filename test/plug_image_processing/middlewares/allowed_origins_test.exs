defmodule PlugImageProcessing.Middlewares.AllowedOriginsTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Middlewares.AllowedOrigins

  describe "enabled?" do
    test "returns true when url param exists and allowed_origins is configured" do
      config = %Config{path: "/imageproxy", allowed_origins: ["example.com"]}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{"url" => "http://example.com/image.jpg"})

      assert PlugImageProcessing.Middleware.enabled?(middleware, conn)
    end

    test "returns false when url param is nil" do
      config = %Config{path: "/imageproxy", allowed_origins: ["example.com"]}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{})

      refute PlugImageProcessing.Middleware.enabled?(middleware, conn)
    end

    test "returns false when allowed_origins is nil" do
      config = %Config{path: "/imageproxy", allowed_origins: nil}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{"url" => "http://example.com/image.jpg"})

      refute PlugImageProcessing.Middleware.enabled?(middleware, conn)
    end

    test "returns false when allowed_origins is not a list" do
      config = %Config{path: "/imageproxy", allowed_origins: "example.com"}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{"url" => "http://example.com/image.jpg"})

      refute PlugImageProcessing.Middleware.enabled?(middleware, conn)
    end
  end

  describe "run" do
    test "allows request when origin is in allowed list" do
      config = %Config{path: "/imageproxy", allowed_origins: ["example.com", "test.com"]}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{"url" => "http://example.com/image.jpg"})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn == conn
      refute result_conn.halted
    end

    test "allows request with URL encoded URL" do
      config = %Config{path: "/imageproxy", allowed_origins: ["example.com"]}
      middleware = %AllowedOrigins{config: config}
      encoded_url = URI.encode_www_form("http://example.com/image.jpg")
      conn = conn(:get, "/imageproxy/resize", %{"url" => encoded_url})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn == conn
      refute result_conn.halted
    end

    test "blocks request when origin is not in allowed list" do
      config = %Config{path: "/imageproxy", allowed_origins: ["example.com"]}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{"url" => "http://malicious.com/image.jpg"})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn.status == 403
      assert result_conn.resp_body == "Forbidden: Unallowed origin"
      assert result_conn.halted
    end

    test "blocks request when URL is nil" do
      config = %Config{path: "/imageproxy", allowed_origins: ["example.com"]}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{"url" => nil})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn.status == 403
      assert result_conn.resp_body == "Forbidden: Unallowed origin"
      assert result_conn.halted
    end

    test "blocks request when URL cannot be parsed" do
      config = %Config{path: "/imageproxy", allowed_origins: ["example.com"]}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{"url" => "invalid-url"})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn.status == 403
      assert result_conn.resp_body == "Forbidden: Unallowed origin"
      assert result_conn.halted
    end

    test "blocks request when parsed URL has no host" do
      config = %Config{path: "/imageproxy", allowed_origins: ["example.com"]}
      middleware = %AllowedOrigins{config: config}
      conn = conn(:get, "/imageproxy/resize", %{"url" => "/relative/path.jpg"})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn.status == 403
      assert result_conn.resp_body == "Forbidden: Unallowed origin"
      assert result_conn.halted
    end
  end
end
