defmodule PlugImageProcessing.Middlewares.SignatureKeyTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Middlewares.SignatureKey

  describe "generate_signature/2" do
    test "generates correct signature for simple URL" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      url = "/imageproxy/resize?width=100&url=http://example.com/image.jpg"

      signature = SignatureKey.generate_signature(url, config)

      expected = Base.url_encode64(:crypto.mac(:hmac, :sha256, "secret", "resizeurl=http%3A%2F%2Fexample.com%2Fimage.jpg&width=100"))
      assert signature == expected
    end

    test "generates signature with sorted query parameters" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      url = "/imageproxy/resize?width=100&height=200&url=http://example.com/image.jpg&quality=80"

      signature = SignatureKey.generate_signature(url, config)

      expected = Base.url_encode64(:crypto.mac(:hmac, :sha256, "secret", "resizeheight=200&quality=80&url=http%3A%2F%2Fexample.com%2Fimage.jpg&width=100"))
      assert signature == expected
    end

    test "generates signature excluding existing sign parameter" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      url = "/imageproxy/resize?width=100&url=http://example.com/image.jpg&sign=old_signature"

      signature = SignatureKey.generate_signature(url, config)

      expected = Base.url_encode64(:crypto.mac(:hmac, :sha256, "secret", "resizeurl=http%3A%2F%2Fexample.com%2Fimage.jpg&width=100"))
      assert signature == expected
    end

    test "generates signature for URL with no query parameters" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      url = "/imageproxy/resize?"

      signature = SignatureKey.generate_signature(url, config)

      expected = Base.url_encode64(:crypto.mac(:hmac, :sha256, "secret", "resize"))
      assert signature == expected
    end

    test "generates signature with different operation" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      url = "/imageproxy/crop?width=100&height=100&url=http://example.com/image.jpg"

      signature = SignatureKey.generate_signature(url, config)

      expected = Base.url_encode64(:crypto.mac(:hmac, :sha256, "secret", "cropheight=100&url=http%3A%2F%2Fexample.com%2Fimage.jpg&width=100"))
      assert signature == expected
    end

    test "generates signature with different secret key" do
      config = %Config{path: "/imageproxy", url_signature_key: "different_secret"}
      url = "/imageproxy/resize?width=100&url=http://example.com/image.jpg"

      signature = SignatureKey.generate_signature(url, config)

      expected = Base.url_encode64(:crypto.mac(:hmac, :sha256, "different_secret", "resizeurl=http%3A%2F%2Fexample.com%2Fimage.jpg&width=100"))
      assert signature == expected
    end
  end

  describe "PlugImageProcessing.Middleware implementation" do
    test "enabled?/2 returns true when url_signature_key is a binary" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      middleware = %SignatureKey{config: config}
      conn = conn(:get, "/imageproxy/resize")

      assert PlugImageProcessing.Middleware.enabled?(middleware, conn) == true
    end

    test "enabled?/2 returns false when url_signature_key is nil" do
      config = %Config{path: "/imageproxy", url_signature_key: nil}
      middleware = %SignatureKey{config: config}
      conn = conn(:get, "/imageproxy/resize")

      assert PlugImageProcessing.Middleware.enabled?(middleware, conn) == false
    end

    test "enabled?/2 returns false when url_signature_key is not a binary" do
      config = %Config{path: "/imageproxy", url_signature_key: 123}
      middleware = %SignatureKey{config: config}
      conn = conn(:get, "/imageproxy/resize")

      assert PlugImageProcessing.Middleware.enabled?(middleware, conn) == false
    end

    test "run/2 allows request with valid signature" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      middleware = %SignatureKey{config: config}

      # Generate valid signature
      url = "/imageproxy/resize?width=100&url=http://example.com/image.jpg"
      valid_signature = SignatureKey.generate_signature(url, config)

      conn = conn(:get, "/imageproxy/resize", %{"width" => "100", "url" => "http://example.com/image.jpg", "sign" => valid_signature})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn == conn
      refute result_conn.halted
    end

    test "run/2 blocks request with invalid signature" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      middleware = %SignatureKey{config: config}

      conn = conn(:get, "/imageproxy/resize", %{"width" => "100", "url" => "http://example.com/image.jpg", "sign" => "invalid_signature"})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn.status == 401
      assert result_conn.resp_body == "Unauthorized: Invalid signature"
      assert result_conn.halted
    end

    test "run/2 blocks request with missing signature" do
      config = %Config{path: "/imageproxy", url_signature_key: "secret"}
      middleware = %SignatureKey{config: config}

      conn = conn(:get, "/imageproxy/resize", %{"width" => "100", "url" => "http://example.com/image.jpg"})

      result_conn = PlugImageProcessing.Middleware.run(middleware, conn)

      assert result_conn.status == 401
      assert result_conn.resp_body == "Unauthorized: Invalid signature"
      assert result_conn.halted
    end
  end
end
