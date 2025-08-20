defmodule PlugImageProcessing.Operations.ExtractAreaTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Operations.Crop
  alias PlugImageProcessing.Operations.ExtractArea
  alias Vix.Vips.Image

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy"}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "creates extract area operation with valid parameters", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200",
        "left" => "10",
        "top" => "20"
      }

      {:ok, operation} = ExtractArea.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == 200
      assert operation.left == 10
      assert operation.top == 20
    end

    test "creates extract area operation with default left and top", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200"
      }

      {:ok, operation} = ExtractArea.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 100
      assert operation.height == 200
      assert operation.left == 0
      assert operation.top == 0
    end

    test "creates extract area operation with integer parameters", %{image: image, config: config} do
      params = %{
        "width" => 150,
        "height" => 250,
        "left" => 15,
        "top" => 25
      }

      {:ok, operation} = ExtractArea.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == 150
      assert operation.height == 250
      assert operation.left == 15
      assert operation.top == 25
    end

    test "creates extract area operation when width is missing (uses nil)", %{image: image, config: config} do
      params = %{
        "height" => "200",
        "left" => "10",
        "top" => "20"
      }

      {:ok, operation} = ExtractArea.new(image, params, config)

      assert %Crop{} = operation
      assert operation.image == image
      assert operation.width == nil
      assert operation.height == 200
      assert operation.left == 10
      assert operation.top == 20
    end

    test "creates extract area operation when height is missing (uses nil)", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "left" => "10",
        "top" => "20"
      }

      {:ok, operation} = ExtractArea.new(image, params, config)

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

      result = ExtractArea.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when height is invalid", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "invalid",
        "left" => "10",
        "top" => "20"
      }

      result = ExtractArea.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when left is invalid", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200",
        "left" => "invalid",
        "top" => "20"
      }

      result = ExtractArea.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when top is invalid", %{image: image, config: config} do
      params = %{
        "width" => "100",
        "height" => "200",
        "left" => "10",
        "top" => "invalid"
      }

      result = ExtractArea.new(image, params, config)

      assert {:error, :bad_request} = result
    end
  end
end
