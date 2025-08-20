defmodule PlugImageProcessing.Operations.FlipTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Operations.Flip
  alias Vix.Vips.Image

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy"}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "creates flip operation with default horizontal direction", %{image: image, config: config} do
      params = %{}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == :VIPS_DIRECTION_HORIZONTAL
    end

    test "creates flip operation with flip=x parameter", %{image: image, config: config} do
      params = %{"flip" => "x"}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == :VIPS_DIRECTION_HORIZONTAL
    end

    test "creates flip operation with flip=y parameter", %{image: image, config: config} do
      params = %{"flip" => "y"}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == :VIPS_DIRECTION_VERTICAL
    end

    test "creates flip operation with direction=x parameter", %{image: image, config: config} do
      params = %{"direction" => "x"}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == :VIPS_DIRECTION_HORIZONTAL
    end

    test "creates flip operation with direction=y parameter", %{image: image, config: config} do
      params = %{"direction" => "y"}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == :VIPS_DIRECTION_VERTICAL
    end

    test "creates flip operation with flip=true parameter", %{image: image, config: config} do
      params = %{"flip" => "true"}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == true
    end

    test "creates flip operation with flip=false parameter", %{image: image, config: config} do
      params = %{"flip" => "false"}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == false
    end

    test "direction parameter overrides flip parameter", %{image: image, config: config} do
      params = %{"flip" => "x", "direction" => "y"}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == :VIPS_DIRECTION_VERTICAL
    end

    test "boolean flip parameter overrides direction parameter", %{image: image, config: config} do
      params = %{"direction" => "y", "flip" => "true"}

      {:ok, operation} = Flip.new(image, params, config)

      assert %Flip{} = operation
      assert operation.image == image
      assert operation.direction == true
    end
  end

  describe "PlugImageProcessing.Operation implementation" do
    test "valid?/1 always returns true", %{image: image, config: config} do
      {:ok, operation} = Flip.new(image, %{}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == true
    end

    test "process/2 flips image horizontally with boolean true", %{image: image, config: config} do
      {:ok, operation} = Flip.new(image, %{"flip" => "true"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == Image.width(image)
      assert Image.height(result_image) == Image.height(image)
    end

    test "process/2 flips image horizontally with direction", %{image: image, config: config} do
      {:ok, operation} = Flip.new(image, %{"direction" => "x"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == Image.width(image)
      assert Image.height(result_image) == Image.height(image)
    end

    test "process/2 flips image vertically", %{image: image, config: config} do
      {:ok, operation} = Flip.new(image, %{"direction" => "y"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == Image.width(image)
      assert Image.height(result_image) == Image.height(image)
    end

    test "process/2 handles boolean false direction", %{image: image, config: config} do
      {:ok, operation} = Flip.new(image, %{"flip" => "false"}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == Image.width(image)
      assert Image.height(result_image) == Image.height(image)
    end
  end
end
