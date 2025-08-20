defmodule PlugImageProcessing.Operations.EchoTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Operations.Echo
  alias Vix.Vips.Image

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy"}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "creates echo operation with image", %{image: image, config: config} do
      params = %{}

      {:ok, operation} = Echo.new(image, params, config)

      assert %Echo{} = operation
      assert operation.image == image
    end

    test "creates echo operation ignoring params", %{image: image, config: config} do
      params = %{"width" => "100", "height" => "200", "ignored" => "value"}

      {:ok, operation} = Echo.new(image, params, config)

      assert %Echo{} = operation
      assert operation.image == image
    end

    test "creates echo operation with nil image", %{config: config} do
      params = %{}

      {:ok, operation} = Echo.new(nil, params, config)

      assert %Echo{} = operation
      assert operation.image == nil
    end
  end

  describe "PlugImageProcessing.Operation implementation" do
    test "valid?/1 always returns true", %{image: image, config: config} do
      {:ok, operation} = Echo.new(image, %{}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == true
    end

    test "valid?/1 returns true even with nil image", %{config: config} do
      {:ok, operation} = Echo.new(nil, %{}, config)

      assert PlugImageProcessing.Operation.valid?(operation) == true
    end

    test "process/2 returns the original image unchanged", %{image: image, config: config} do
      {:ok, operation} = Echo.new(image, %{}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert result_image == image
      # Same reference
      assert result_image === image
    end

    test "process/2 returns nil when image is nil", %{config: config} do
      {:ok, operation} = Echo.new(nil, %{}, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert result_image == nil
    end

    test "process/2 ignores config parameter", %{image: image} do
      {:ok, operation} = Echo.new(image, %{}, %Config{path: "/different"})
      different_config = %Config{path: "/another", http_client_timeout: 5000}

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, different_config)

      assert result_image == image
    end
  end
end
