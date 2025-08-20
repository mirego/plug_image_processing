defmodule PlugImageProcessing.Operations.SmartcropTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Operations.Crop
  alias PlugImageProcessing.Operations.Smartcrop
  alias Vix.Vips.Image

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy"}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "creates smartcrop operation with valid parameters", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200"
      }

      {:ok, operation} = Smartcrop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == 200
      assert operation.gravity == "smart"
    end

    test "creates smartcrop operation with integer parameters", %{image: image, config: config} do
      params = %{
        "width" => 150,
        "height" => 250
      }

      {:ok, operation} = Smartcrop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 150
      assert operation.height == 250
      assert operation.gravity == "smart"
    end

    test "creates smartcrop operation when width is missing (uses nil)", %{image: image, config: config} do
      params = %{
        "height" => "200"
      }

      {:ok, operation} = Smartcrop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == nil
      assert operation.height == 200
      assert operation.gravity == "smart"
    end

    test "creates smartcrop operation when height is missing (uses nil)", %{image: image, config: config} do
      params = %{
        "width" => "100"
      }

      {:ok, operation} = Smartcrop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == nil
      assert operation.gravity == "smart"
    end

    test "returns error when width is invalid", %{image: image, config: config} do
      params = %{
        "width" => "invalid",
        "height" => "200"
      }

      result = Smartcrop.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when height is invalid", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "invalid"
      }

      result = Smartcrop.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "creates smartcrop operation when both width and height are missing (uses nil)", %{image: image, config: config} do
      params = %{}

      {:ok, operation} = Smartcrop.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == nil
      assert operation.height == nil
      assert operation.gravity == "smart"
    end

    test "returns error when both width and height are invalid", %{image: image, config: config} do
      params = %{
        "width" => "invalid",
        "height" => "also_invalid"
      }

      result = Smartcrop.new(image, params, config)

      assert {:error, :bad_request} = result
    end
  end
end
