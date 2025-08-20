defmodule PlugImageProcessing.Operations.ResizeTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Operations.Resize
  alias Vix.Vips.Image

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy"}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "creates resize operation with width parameter", %{image: image, config: config} do
      params = %{"width" => "100"}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == nil
    end

    test "creates resize operation with w parameter (short form)", %{image: image, config: config} do
      params = %{"w" => "150"}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.image == image
      assert operation.width == 150
      assert operation.height == nil
    end

    test "creates resize operation with height parameter", %{image: image, config: config} do
      params = %{"height" => "200"}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.image == image
      assert operation.width == nil
      assert operation.height == 200
    end

    test "creates resize operation with h parameter (short form)", %{image: image, config: config} do
      params = %{"h" => "250"}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.image == image
      assert operation.width == nil
      assert operation.height == 250
    end

    test "creates resize operation with both width and height", %{image: image, config: config} do
      params = %{"width" => "100", "height" => "200"}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == 200
    end

    test "creates resize operation with integer parameters", %{image: image, config: config} do
      params = %{"width" => 300, "height" => 400}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.image == image
      assert operation.width == 300
      assert operation.height == 400
    end

    test "w parameter is used when width is not present", %{image: image, config: config} do
      params = %{"w" => "100"}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.width == 100
    end

    test "h parameter is used when height is not present", %{image: image, config: config} do
      params = %{"h" => "100"}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.height == 100
    end

    test "returns error when width parameter is invalid", %{image: image, config: config} do
      params = %{"width" => "invalid"}

      result = Resize.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when height parameter is invalid", %{image: image, config: config} do
      params = %{"height" => "invalid"}

      result = Resize.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "creates resize operation with no parameters", %{image: image, config: config} do
      params = %{}

      {:ok, operation} = Resize.new(image, params, config)

      assert %Resize{} = operation
      assert operation.image == image
      assert operation.width == nil
      assert operation.height == nil
    end
  end

  describe "PlugImageProcessing.Operation implementation" do
    test "valid?/1 returns true when width is present", %{image: image, config: config} do
      {:ok, operation} = Resize.new(image, %{"width" => "100"}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == true
    end

    test "valid?/1 returns error when width is missing", %{image: image, config: config} do
      {:ok, operation} = Resize.new(image, %{"height" => "100"}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == {:error, :missing_width}
    end

    test "valid?/1 returns error when width is nil", %{image: image, config: config} do
      {:ok, operation} = Resize.new(image, %{}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == {:error, :missing_width}
    end

    test "process/2 resizes image with width only", %{image: image, config: config} do
      {:ok, operation} = Resize.new(image, %{"width" => "100"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
      # Height should be proportionally scaled
      original_ratio = Image.height(image) / Image.width(image)
      expected_height = round(100 * original_ratio)
      assert Image.height(result_image) == expected_height
    end

    test "process/2 resizes image with width and height", %{image: image, config: config} do
      {:ok, operation} = Resize.new(image, %{"width" => "100", "height" => "200"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
      assert Image.height(result_image) == 200
    end

    test "process/2 handles different aspect ratios", %{image: image, config: config} do
      {:ok, operation} = Resize.new(image, %{"width" => "50", "height" => "300"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 50
      assert Image.height(result_image) == 300
    end

    test "process/2 ignores config parameter", %{image: image} do
      {:ok, operation} = Resize.new(image, %{"width" => "100"}, %Config{path: "/different"})
      different_config = %Config{path: "/another", http_client_timeout: 5000}

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, different_config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
    end
  end
end
