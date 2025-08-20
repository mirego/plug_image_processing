defmodule PlugImageProcessing.WebTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias PlugImageProcessing.Web
  alias Vix.Vips.Image

  defmodule HTTPMock do
    @moduledoc false
    @behaviour PlugImageProcessing.Sources.HTTPClient

    @image File.read!("test/support/image.jpg")
    @gif_image File.read!("test/support/image.gif")
    @svg_image File.read!("test/support/image.svg")

    def get("http://example.org/valid.jpg", _), do: {:ok, @image, [{"Content-type", "image/jpg"}]}
    def get("http://example.org/valid.gif", _), do: {:ok, @gif_image, [{"Content-type", "image/gif"}]}
    def get("http://example.org/valid.svg", _), do: {:ok, @svg_image, [{"Content-type", "image/svg"}]}
    def get("http://example.org/valid-xml.svg", _), do: {:ok, @svg_image, [{"Content-type", "image/svg+xml"}]}
    def get("http://example.org/retry.jpg", _), do: {:ok, @image, [{"Content-type", "image/jpg"}]}
    def get("http://example.org/404.jpg", _), do: {:error, "404 Not found"}
    def get("http://example.org/index.html", _), do: {:ok, "<html></html>", [{"Content-type", "text/html"}]}

    def get("http://example.org/timeout.jpg", _) do
      Process.sleep(1000)
      {:ok, @image, [{"Content-type", "image/jpg"}]}
    end
  end

  setup do
    config = [
      path: "/imageproxy",
      http_client: HTTPMock
    ]

    {:ok, config: config}
  end

  defp conn_to_image(conn) do
    Image.new_from_buffer(conn.resp_body)
  end

  describe "error handling" do
    test "source URL timeout", %{config: config} do
      config = Keyword.put(config, :http_client_timeout, 1)

      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/timeout.jpg"})
      conn = Web.call(conn, plug_opts)

      assert conn.resp_body === "Bad request: :timeout"
      assert conn.status === 400
    end

    test "source URL invalid type", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/index.html"})
      conn = Web.call(conn, plug_opts)

      assert conn.resp_body === "Bad request: :invalid_file_type"
      assert conn.status === 400
    end

    test "source URL 404", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/404.jpg"})
      conn = Web.call(conn, plug_opts)

      assert conn.resp_body === "Bad request: :invalid_file"
      assert conn.status === 400
    end

    test "source URL 404 with retry onerror", %{config: config} do
      on_error = fn conn ->
        params = %{
          "url" => "http://example.org/retry.jpg",
          "width" => 10
        }

        {:retry, %{conn | params: params}}
      end

      config = Keyword.put(config, :onerror, %{"test" => on_error})
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/404.jpg", onerror: "test"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert get_resp_header(conn, "cache-control") === ["private, no-cache, no-store, must-revalidate"]
      assert Image.width(image) === 10
    end

    test "source URL 404 with halt onerror", %{config: config} do
      on_error = fn conn ->
        conn = send_resp(conn, 500, "Oops")
        {:halt, conn}
      end

      config = Keyword.put(config, :onerror, %{"test" => on_error})
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/404.jpg", onerror: "test"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "cache-control") === ["private, no-cache, no-store, must-revalidate"]
      assert conn.status === 500
      assert conn.resp_body === "Oops"
    end

    test "source URL 404 with conn update onerror", %{config: config} do
      on_error = fn conn ->
        put_resp_header(conn, "x-image-error", "Test")
      end

      config = Keyword.put(config, :onerror, %{"test" => on_error})
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/404.jpg", onerror: "test"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "x-image-error") === ["Test"]
      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_file"
    end
  end

  describe "operations" do
    test "resize", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
    end

    test "resize svg", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/valid.svg"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
    end

    test "echo gif", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy", %{url: "http://example.org/valid.gif"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 200
    end

    test "echo svg", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy", %{url: "http://example.org/valid.svg"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 200
    end

    test "echo svg+xml", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy", %{url: "http://example.org/valid-xml.svg"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 200
    end

    test "echo redirect gif", %{config: config} do
      config = Keyword.put(config, :source_url_redirect_operations, [""])
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy", %{url: "http://example.org/valid.gif"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "location") === ["http://example.org/valid.gif"]
      assert conn.status === 301
    end

    test "crop", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/crop", %{width: 20, height: 50, url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
      assert Image.height(image) === 50
    end

    test "info", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/info", %{url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      image_metadata = Jason.decode!(conn.resp_body)

      assert image_metadata["width"] === 512
      assert image_metadata["height"] === 512
      assert image_metadata["has_alpha"] === false
      assert image_metadata["channels"] === 3
    end

    test "pipeline", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/pipeline", %{operations: Jason.encode!([%{operation: "crop", params: %{width: 20, height: 50}}]), url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
      assert Image.height(image) === 50
    end

    test "pipeline info", %{config: config} do
      plug_opts = Web.init(config)

      conn =
        conn(:get, "/imageproxy/pipeline", %{
          operations: Jason.encode!([%{operation: "crop", params: %{width: 20, height: 50}}, %{operation: "info"}]),
          url: "http://example.org/valid.jpg"
        })

      conn = Web.call(conn, plug_opts)

      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_operation"
    end
  end

  describe "config handling" do
    test "config as module and function" do
      defmodule ConfigModule do
        @moduledoc false
        def get_config do
          [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock]
        end
      end

      plug_opts = Web.init({ConfigModule, :get_config})
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
    end

    test "config as module, function and args" do
      defmodule ConfigModuleWithArgs do
        @moduledoc false
        def get_config(path, client) do
          [path: path, http_client: client]
        end
      end

      plug_opts = Web.init({ConfigModuleWithArgs, :get_config, ["/imageproxy", PlugImageProcessing.WebTest.HTTPMock]})
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
    end

    test "config as zero-arity function" do
      config_fn = fn -> [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock] end
      plug_opts = Web.init(config_fn)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
    end

    test "invalid config raises error" do
      plug_opts = Web.init("invalid_config")
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/valid.jpg"})

      assert_raise ArgumentError, ~r/Invalid config/, fn ->
        Web.call(conn, plug_opts)
      end
    end
  end

  describe "path handling" do
    test "request outside config path" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock]
      plug_opts = Web.init(config)
      conn = conn(:get, "/other/path", %{})
      conn = Web.call(conn, plug_opts)

      # Should pass through without processing
      assert conn.status === nil
      refute conn.halted
    end

    test "root path with trailing slash" do
      config = [path: "/imageproxy/", http_client: PlugImageProcessing.WebTest.HTTPMock]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
    end

    test "operation with extra path segments" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize/extra/segments", %{width: 20, url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)
      {:ok, image} = conn_to_image(conn)

      assert Image.width(image) === 20
    end
  end

  describe "redirect handling" do
    test "redirect with POST method" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, source_url_redirect_operations: ["resize"]]
      plug_opts = Web.init(config)
      conn = conn(:post, "/imageproxy/resize", %{url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "location") === ["http://example.org/valid.jpg"]
      # temporary_redirect for POST
      assert conn.status === 307
    end

    test "redirect with HEAD method" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, source_url_redirect_operations: ["resize"]]
      plug_opts = Web.init(config)
      conn = conn(:head, "/imageproxy/resize", %{url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "location") === ["http://example.org/valid.jpg"]
      # moved_permanently for HEAD
      assert conn.status === 301
    end

    test "redirect with PUT method" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, source_url_redirect_operations: ["resize"]]
      plug_opts = Web.init(config)
      conn = conn(:put, "/imageproxy/resize", %{url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "location") === ["http://example.org/valid.jpg"]
      # temporary_redirect for PUT
      assert conn.status === 307
    end

    test "info operation with redirect" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, source_url_redirect_operations: ["info"]]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/info", %{url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "location") === ["http://example.org/valid.jpg"]
      assert conn.status === 301
    end

    test "info operation with POST redirect" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, source_url_redirect_operations: ["info"]]
      plug_opts = Web.init(config)
      conn = conn(:post, "/imageproxy/info", %{url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "location") === ["http://example.org/valid.jpg"]
      assert conn.status === 307
    end
  end

  describe "error handling without retry" do
    test "error without onerror handler" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/404.jpg"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_file"
      assert get_resp_header(conn, "cache-control") === ["private, no-cache, no-store, must-revalidate"]
    end

    test "error with invalid onerror key" do
      on_error = fn conn ->
        {:retry, %{conn | params: %{"url" => "http://example.org/retry.jpg", "width" => 10}}}
      end

      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, onerror: %{"valid" => on_error}]
      plug_opts = Web.init(config)
      # Use "invalid" key that doesn't exist in onerror map
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/404.jpg", onerror: "invalid"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_file"
    end

    test "error with nil onerror handler" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, onerror: %{"test" => nil}]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/404.jpg", onerror: "test"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_file"
    end

    test "retry that also fails" do
      on_error = fn conn ->
        # Retry with another failing URL
        {:retry, %{conn | params: %{"url" => "http://example.org/404.jpg", "width" => 10}}}
      end

      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, onerror: %{"test" => on_error}]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/404.jpg", onerror: "test"})
      conn = Web.call(conn, plug_opts)

      # After retry fails, it should return the error
      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_file"
      assert get_resp_header(conn, "cache-control") === ["private, no-cache, no-store, must-revalidate"]
    end
  end

  describe "invalid operation handling" do
    test "invalid operation name" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/invalid_op", %{url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_operation"
    end

    test "missing required params" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock]
      plug_opts = Web.init(config)
      # resize requires width
      conn = conn(:get, "/imageproxy/resize", %{url: "http://example.org/valid.jpg"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 400
      assert conn.resp_body === "Bad request: :missing_width"
    end
  end

  describe "info operation error handling" do
    test "info with source error" do
      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/info", %{url: "http://example.org/404.jpg"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_file"
      assert get_resp_header(conn, "cache-control") === ["private, no-cache, no-store, must-revalidate"]
    end

    test "info with onerror retry" do
      on_error = fn conn ->
        {:retry, %{conn | params: %{"url" => "http://example.org/valid.jpg"}}}
      end

      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, onerror: %{"test" => on_error}]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/info", %{url: "http://example.org/404.jpg", onerror: "test"})
      conn = Web.call(conn, plug_opts)

      image_metadata = Jason.decode!(conn.resp_body)
      assert image_metadata["width"] === 512
      assert image_metadata["height"] === 512
    end

    test "info with onerror halt" do
      on_error = fn conn ->
        conn = send_resp(conn, 503, "Service Unavailable")
        {:halt, conn}
      end

      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, onerror: %{"test" => on_error}]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/info", %{url: "http://example.org/404.jpg", onerror: "test"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 503
      assert conn.resp_body === "Service Unavailable"
    end

    test "info with onerror conn update" do
      on_error = fn conn ->
        put_resp_header(conn, "x-error", "info-failed")
      end

      config = [path: "/imageproxy", http_client: PlugImageProcessing.WebTest.HTTPMock, onerror: %{"test" => on_error}]
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/info", %{url: "http://example.org/404.jpg", onerror: "test"})
      conn = Web.call(conn, plug_opts)

      assert get_resp_header(conn, "x-error") === ["info-failed"]
      assert conn.status === 400
      assert conn.resp_body === "Bad request: :invalid_file"
    end
  end
end
