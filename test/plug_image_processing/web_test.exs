defmodule PlugImageProcessing.WebTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PlugImageProcessing.Web
  alias Vix.Vips.Image

  defmodule HTTPMock do
    @image File.read!("test/support/image.jpg")
    @gif_image File.read!("test/support/image.gif")

    @behaviour PlugImageProcessing.Sources.HTTPClient
    def get("http://example.org/valid.jpg", _), do: {:ok, @image, [{"Content-type", "image/jpg"}]}
    def get("http://example.org/valid.gif", _), do: {:ok, @gif_image, [{"Content-type", "image/gif"}]}
    def get("http://example.org/retry.jpg", _), do: {:ok, @image, [{"Content-type", "image/jpg"}]}
    def get("http://example.org/404.jpg", _), do: {:error, "404 Not found"}

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
      config = Keyword.merge(config, http_client_timeout: 1)

      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy/resize", %{width: 20, url: "http://example.org/timeout.jpg"})
      conn = Web.call(conn, plug_opts)

      assert conn.resp_body === "Bad request: :timeout"
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

    test "echo gif", %{config: config} do
      plug_opts = Web.init(config)
      conn = conn(:get, "/imageproxy", %{url: "http://example.org/valid.gif"})
      conn = Web.call(conn, plug_opts)

      assert conn.status === 200
    end

    test "echo redirect gif", %{config: config} do
      config = Keyword.merge(config, source_url_redirect_operations: [""])
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
  end
end
