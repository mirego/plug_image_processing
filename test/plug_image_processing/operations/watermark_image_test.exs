defmodule PlugImageProcessing.Operations.WatermarkImageTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Operations.WatermarkImage
  alias Vix.Vips.Image

  defmodule HTTPMock do
    @moduledoc false
    @behaviour PlugImageProcessing.Sources.HTTPClient

    @image File.read!("test/support/image.jpg")

    def get("http://example.org/watermark.jpg", _), do: {:ok, @image, [{"Content-type", "image/jpg"}]}
    def get("http://example.org/404.jpg", _), do: {:error, "404 Not found"}
  end

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy", http_client: HTTPMock}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "creates watermark operation with valid parameters", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => "10",
        "top" => "20",
        "right" => "30",
        "bottom" => "40"
      }

      {:ok, operation} = WatermarkImage.new(image, params, config)

      assert %WatermarkImage{} = operation
      assert operation.image == image
      assert %Image{} = operation.sub
      assert operation.left == 10
      assert operation.top == 20
      assert operation.right == 30
      assert operation.bottom == 40
    end

    test "creates watermark operation with integer parameters", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => 15,
        "top" => 25,
        "right" => 35,
        "bottom" => 45
      }

      {:ok, operation} = WatermarkImage.new(image, params, config)

      assert %WatermarkImage{} = operation
      assert operation.image == image
      assert %Image{} = operation.sub
      assert operation.left == 15
      assert operation.top == 25
      assert operation.right == 35
      assert operation.bottom == 45
    end

    test "returns error when watermark image URL is invalid", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/404.jpg",
        "left" => "10",
        "top" => "20",
        "right" => "30",
        "bottom" => "40"
      }

      result = WatermarkImage.new(image, params, config)

      assert {:error, :invalid_file} = result
    end

    test "returns error when left parameter is invalid", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => "invalid",
        "top" => "20",
        "right" => "30",
        "bottom" => "40"
      }

      result = WatermarkImage.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when top parameter is invalid", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => "10",
        "top" => "invalid",
        "right" => "30",
        "bottom" => "40"
      }

      result = WatermarkImage.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when right parameter is invalid", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => "10",
        "top" => "20",
        "right" => "invalid",
        "bottom" => "40"
      }

      result = WatermarkImage.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when bottom parameter is invalid", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => "10",
        "top" => "20",
        "right" => "30",
        "bottom" => "invalid"
      }

      result = WatermarkImage.new(image, params, config)

      assert {:error, :bad_request} = result
    end
  end

  describe "PlugImageProcessing.Operation implementation" do
    test "valid?/1 returns true when sub image exists", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => "10",
        "top" => "20",
        "right" => "30",
        "bottom" => "40"
      }

      {:ok, operation} = WatermarkImage.new(image, params, config)

      assert PlugImageProcessing.Operation.valid?(operation) == true
    end

    test "valid?/1 returns error when sub image is nil" do
      operation = %WatermarkImage{
        image: nil,
        sub: nil,
        left: 10,
        top: 20,
        right: 30,
        bottom: 40
      }

      assert PlugImageProcessing.Operation.valid?(operation) == {:error, :missing_image}
    end

    test "process/2 composites watermark with left and top positioning", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => "10",
        "top" => "20"
      }

      {:ok, operation} = WatermarkImage.new(image, params, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == Image.width(image)
      assert Image.height(result_image) == Image.height(image)
    end

    test "process/2 composites watermark with right and bottom positioning", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "right" => "30",
        "bottom" => "40"
      }

      {:ok, operation} = WatermarkImage.new(image, params, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == Image.width(image)
      assert Image.height(result_image) == Image.height(image)
    end

    test "process/2 composites watermark with default positioning (0,0)", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg"
      }

      {:ok, operation} = WatermarkImage.new(image, params, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == Image.width(image)
      assert Image.height(result_image) == Image.height(image)
    end

    test "process/2 handles mixed positioning parameters", %{image: image, config: config} do
      params = %{
        "image" => "http://example.org/watermark.jpg",
        "left" => "10",
        "bottom" => "40"
      }

      {:ok, operation} = WatermarkImage.new(image, params, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == Image.width(image)
      assert Image.height(result_image) == Image.height(image)
    end
  end
end
