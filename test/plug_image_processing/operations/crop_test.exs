defmodule PlugImageProcessing.Operations.CropTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Operations.Crop
  alias Vix.Vips.Image

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy"}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "creates crop operation with all parameters", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200",
        "left" => "10",
        "top" => "20"
      }

      {:ok, operation} = Crop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == 200
      assert operation.left == 10
      assert operation.top == 20
      assert operation.gravity == nil
    end

    test "creates crop operation with gravity parameter", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200",
        "left" => "10",
        "top" => "20",
        "gravity" => "smart"
      }

      {:ok, operation} = Crop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == 200
      assert operation.left == 10
      assert operation.top == 20
      assert operation.gravity == "smart"
    end

    test "creates crop operation with default left and top", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200"
      }

      {:ok, operation} = Crop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == 200
      assert operation.left == 0
      assert operation.top == 0
    end

    test "creates crop operation with integer parameters", %{image: image, config: config} do
      params = %{
        "width" => 150,
        "height" => 250,
        "left" => 15,
        "top" => 25
      }

      {:ok, operation} = Crop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 150
      assert operation.height == 250
      assert operation.left == 15
      assert operation.top == 25
    end

    test "creates crop operation with only width and height", %{image: image, config: config} do
      params = %{
        "width" => "300",
        "height" => "400"
      }

      {:ok, operation} = Crop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 300
      assert operation.height == 400
      assert operation.left == 0
      assert operation.top == 0
    end

    test "creates crop operation when width is missing (uses nil)", %{image: image, config: config} do
      params = %{
        "height" => "200",
        "left" => "10",
        "top" => "20"
      }

      {:ok, operation} = Crop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == nil
      assert operation.height == 200
      assert operation.left == 10
      assert operation.top == 20
    end

    test "creates crop operation when height is missing (uses nil)", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "left" => "10",
        "top" => "20"
      }

      {:ok, operation} = Crop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == nil
      assert operation.left == 10
      assert operation.top == 20
    end

    test "returns error when width is invalid", %{image: image, config: config} do
      params = %{
        "width" => "invalid",
        "height" => "200",
        "left" => "10",
        "top" => "20"
      }

      result = Crop.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when height is invalid", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "invalid",
        "left" => "10",
        "top" => "20"
      }

      result = Crop.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when left is invalid", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200",
        "left" => "invalid",
        "top" => "20"
      }

      result = Crop.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when top is invalid", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200",
        "left" => "10",
        "top" => "invalid"
      }

      result = Crop.new(image, params, config)

      assert {:error, :bad_request} = result
    end
  end

  describe "PlugImageProcessing.Operation implementation" do
    test "valid?/1 returns true when all required parameters are present", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"width" => "100", "height" => "200", "left" => "10", "top" => "20"}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == true
    end

    test "valid?/1 returns error when width is missing", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"height" => "200", "left" => "10", "top" => "20"}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == {:error, :missing_arguments}
    end

    test "valid?/1 returns error when height is missing", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"width" => "100", "left" => "10", "top" => "20"}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == {:error, :missing_arguments}
    end

    test "valid?/1 returns error when top is missing", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"width" => "100", "height" => "200", "left" => "10"}, config)
      operation = %{operation | top: nil}

      assert PlugImageProcessing.Operation.valid?(operation) == {:error, :missing_arguments}
    end

    test "valid?/1 returns error when left is missing", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"width" => "100", "height" => "200", "top" => "20"}, config)
      operation = %{operation | left: nil}

      assert PlugImageProcessing.Operation.valid?(operation) == {:error, :missing_arguments}
    end

    test "process/2 crops image with extract_area", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"width" => "100", "height" => "150", "left" => "10", "top" => "20"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
      assert Image.height(result_image) == 150
    end

    test "process/2 crops image with smart gravity", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"width" => "100", "height" => "100", "left" => "0", "top" => "0", "gravity" => "smart"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
      assert Image.height(result_image) == 100
    end

    test "process/2 crops image from center area", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"width" => "50", "height" => "50", "left" => "25", "top" => "25"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 50
      assert Image.height(result_image) == 50
    end

    test "process/2 crops image from top-left corner", %{image: image, config: config} do
      {:ok, operation} = Crop.new(image, %{"width" => "100", "height" => "100", "left" => "0", "top" => "0"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
      assert Image.height(result_image) == 100
    end

    test "process/2 ignores config parameter", %{image: image} do
      {:ok, operation} = Crop.new(image, %{"width" => "100", "height" => "100", "left" => "10", "top" => "10"}, %Config{path: "/different"})
      different_config = %Config{path: "/another", http_client_timeout: 5000}

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, different_config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
      assert Image.height(result_image) == 100
    end
  end
end
