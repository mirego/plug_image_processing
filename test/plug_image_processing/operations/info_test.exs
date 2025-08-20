defmodule PlugImageProcessing.Operations.InfoTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.ImageMetadata
  alias PlugImageProcessing.Operations.Info
  alias Vix.Vips.Image

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy"}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "always returns invalid operation error", %{image: image, config: config} do
      params = %{}

      result = Info.new(image, params, config)

      assert result == {:error, :invalid_operation}
    end

    test "returns invalid operation error with any params", %{image: image, config: config} do
      params = %{"width" => "100", "height" => "200"}

      result = Info.new(image, params, config)

      assert result == {:error, :invalid_operation}
    end

    test "returns invalid operation error with nil image", %{config: config} do
      params = %{}

      result = Info.new(nil, params, config)

      assert result == {:error, :invalid_operation}
    end

    test "returns invalid operation error with nil config", %{image: image} do
      params = %{}

      result = Info.new(image, params, nil)

      assert result == {:error, :invalid_operation}
    end
  end

  describe "PlugImageProcessing.Info implementation" do
    test "process/1 returns image metadata", %{image: image} do
      operation = %Info{image: image}

      {:ok, metadata} = PlugImageProcessing.Info.process(operation)

      assert %ImageMetadata{} = metadata
      assert metadata.width == Image.width(image)
      assert metadata.height == Image.height(image)
      assert metadata.channels == Image.bands(image)
      assert metadata.has_alpha == Image.has_alpha?(image)
    end

    test "process/1 returns correct metadata for test image", %{image: image} do
      operation = %Info{image: image}

      {:ok, metadata} = PlugImageProcessing.Info.process(operation)

      assert metadata.width == 512
      assert metadata.height == 512
      assert metadata.channels == 3
      assert metadata.has_alpha == false
    end

    test "process/1 works with different image operations" do
      # Use the existing test image and verify the metadata extraction works
      {:ok, image} = Image.new_from_file("test/support/image.jpg")
      operation = %Info{image: image}

      {:ok, metadata} = PlugImageProcessing.Info.process(operation)

      assert is_integer(metadata.width)
      assert is_integer(metadata.height)
      assert is_integer(metadata.channels)
      assert is_boolean(metadata.has_alpha)
      assert metadata.width > 0
      assert metadata.height > 0
      assert metadata.channels > 0
    end
  end
end
