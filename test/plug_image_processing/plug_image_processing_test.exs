defmodule PlugImageProcessingTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias PlugImageProcessing.Config
  alias Vix.Vips.Image

  defmodule HTTPMock do
    @moduledoc false
    @behaviour PlugImageProcessing.Sources.HTTPClient

    @image File.read!("test/support/image.jpg")

    def get("http://example.org/valid.jpg", _), do: {:ok, @image, [{"Content-type", "image/jpg"}]}
    def get("http://example.org/404.jpg", _), do: {:error, "404 Not found"}
  end

  setup do
    config = [
      path: "/imageproxy",
      http_client: HTTPMock
    ]

    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    {:ok, config: config, image: image}
  end

  describe "generate_url" do
    test "valid", %{config: config} do
      url = PlugImageProcessing.generate_url("http://example.com", config, :resize, %{url: "http://bucket.com/test.jpg", width: 10})
      uri = URI.parse(url)
      query_params = Enum.to_list(URI.query_decoder(uri.query))

      assert uri.host === "example.com"
      assert uri.path === "/imageproxy/resize"
      assert {"width", "10"} in query_params
      assert {"url", "http://bucket.com/test.jpg"} in query_params
    end

    test "valid with signature", %{config: config} do
      url_signature_key = "12345"
      config = Keyword.put(config, :url_signature_key, url_signature_key)

      url = PlugImageProcessing.generate_url("http://example.com", config, :resize, %{url: "http://bucket.com/test.jpg", width: 10})

      assert URI.decode_query(URI.parse(url).query)["sign"] === generate_signature_from_url(url_signature_key, "resizeurl=http%3A%2F%2Fbucket.com%2Ftest.jpg&width=10")
    end
  end

  describe "run_middlewares" do
    test "runs enabled middlewares", %{config: config} do
      config_struct = struct!(Config, Keyword.put(config, :url_signature_key, "secret"))
      conn = conn(:get, "/imageproxy/resize", %{"width" => "100", "url" => "http://example.org/valid.jpg"})

      result_conn = PlugImageProcessing.run_middlewares(conn, config_struct)

      assert result_conn.halted
      assert result_conn.status == 401
    end

    test "skips disabled middlewares", %{config: config} do
      config_struct = struct!(Config, config)
      conn = conn(:get, "/imageproxy/resize", %{"width" => "100", "url" => "http://example.org/valid.jpg"})

      result_conn = PlugImageProcessing.run_middlewares(conn, config_struct)

      assert result_conn == conn
      refute result_conn.halted
    end
  end

  describe "params_operations" do
    test "processes valid operations", %{config: config, image: image} do
      config_struct = struct!(Config, config)
      params = %{"width" => "100", "height" => "200"}

      {:ok, result_image} = PlugImageProcessing.params_operations(image, params, config_struct)

      assert %Image{} = result_image
    end

    test "ignores invalid operations", %{config: config, image: image} do
      config_struct = struct!(Config, config)
      params = %{"width" => "100", "invalid_param" => "value"}

      {:ok, result_image} = PlugImageProcessing.params_operations(image, params, config_struct)

      assert %Image{} = result_image
    end

    test "continues processing when single operation fails", %{config: config, image: image} do
      config_struct = struct!(Config, config)
      params = %{"width" => "invalid", "height" => "100"}

      {:ok, result_image} = PlugImageProcessing.params_operations(image, params, config_struct)

      assert %Image{} = result_image
    end
  end

  describe "operations" do
    test "processes valid operation", %{config: config, image: image} do
      config_struct = struct!(Config, config)

      {:ok, result_image} = PlugImageProcessing.operations(image, "resize", %{"width" => "100"}, config_struct)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
    end

    test "returns error for invalid operation name", %{config: config, image: image} do
      config_struct = struct!(Config, config)

      result = PlugImageProcessing.operations(image, "invalid_operation", %{}, config_struct)

      assert {:error, :invalid_operation} = result
    end

    test "returns error for invalid operation", %{config: config, image: image} do
      config_struct = struct!(Config, config)

      result = PlugImageProcessing.operations(image, "resize", %{}, config_struct)

      assert {:error, :missing_width} = result
    end
  end

  describe "info" do
    test "returns image metadata", %{image: image} do
      {:ok, metadata} = PlugImageProcessing.info(image)

      assert metadata.width == Image.width(image)
      assert metadata.height == Image.height(image)
      assert metadata.channels == Image.bands(image)
      assert metadata.has_alpha == Image.has_alpha?(image)
    end
  end

  describe "cast_operation_name" do
    test "returns ok for valid operation name", %{config: config} do
      config_struct = struct!(Config, config)

      assert PlugImageProcessing.cast_operation_name("resize", config_struct) == {:ok, "resize"}
      assert PlugImageProcessing.cast_operation_name("crop", config_struct) == {:ok, "crop"}
      assert PlugImageProcessing.cast_operation_name("", config_struct) == {:ok, ""}
    end

    test "returns error for invalid operation name", %{config: config} do
      config_struct = struct!(Config, config)

      assert PlugImageProcessing.cast_operation_name("invalid", config_struct) == {:error, :invalid_operation}
    end
  end

  describe "get_image" do
    test "returns image for valid URL source", %{config: config} do
      config_struct = struct!(Config, config)
      params = %{"url" => "http://example.org/valid.jpg"}

      {:ok, image, _, _} = PlugImageProcessing.get_image(params, "resize", config_struct)

      assert %Image{} = image
    end

    test "returns error for invalid URL source", %{config: config} do
      config_struct = struct!(Config, config)
      params = %{"url" => "http://example.org/404.jpg"}

      result = PlugImageProcessing.get_image(params, "resize", config_struct)

      assert {:error, :invalid_file} = result
    end

    test "returns error for unknown source", %{config: config} do
      config_struct = struct!(Config, config)
      params = %{"unknown_source" => "value"}

      result = PlugImageProcessing.get_image(params, "resize", config_struct)

      assert {:error, :unknown_source} = result
    end
  end

  describe "write_to_buffer" do
    test "writes image to buffer", %{image: image} do
      {:ok, buffer} = PlugImageProcessing.write_to_buffer(image, ".jpg")

      assert is_binary(buffer)
      assert byte_size(buffer) > 0
    end

    test "returns error for invalid format", %{image: image} do
      result = PlugImageProcessing.write_to_buffer(image, ".invalid")

      assert {:error, _} = result
    end
  end

  defp generate_signature_from_url(url_signature_key, url) do
    Base.url_encode64(:crypto.mac(:hmac, :sha256, url_signature_key, url))
  end
end
