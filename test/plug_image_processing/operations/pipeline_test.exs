defmodule PlugImageProcessing.Operations.PipelineTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Operations.Pipeline
  alias Vix.Vips.Image

  setup do
    {:ok, image} = Image.new_from_file("test/support/image.jpg")
    config = %Config{path: "/imageproxy"}
    {:ok, image: image, config: config}
  end

  describe "new/3" do
    test "creates pipeline operation with valid JSON operations", %{image: image, config: config} do
      operations_json =
        Jason.encode!([
          %{"operation" => "resize", "params" => %{"width" => 100}},
          %{"operation" => "crop", "params" => %{"width" => 50, "height" => 50}}
        ])

      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      assert %Pipeline{} = operation
      assert operation.image == image
      assert length(operation.operations) == 2
      assert hd(operation.operations)["operation"] == "resize"
    end

    test "creates pipeline operation with empty operations array", %{image: image, config: config} do
      operations_json = Jason.encode!([])
      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      assert %Pipeline{} = operation
      assert operation.image == image
      assert operation.operations == []
    end

    test "creates pipeline operation with single operation", %{image: image, config: config} do
      operations_json =
        Jason.encode!([
          %{"operation" => "resize", "params" => %{"width" => 200}}
        ])

      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      assert %Pipeline{} = operation
      assert operation.image == image
      assert length(operation.operations) == 1
      assert hd(operation.operations)["operation"] == "resize"
    end

    test "returns error when operations parameter is missing", %{image: image, config: config} do
      params = %{}

      result = Pipeline.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when operations JSON is invalid", %{image: image, config: config} do
      params = %{"operations" => "{invalid json}"}

      result = Pipeline.new(image, params, config)

      assert {:error, :bad_request} = result
    end

    test "returns error when operations parameter is nil", %{image: image, config: config} do
      params = %{"operations" => nil}

      result = Pipeline.new(image, params, config)

      assert {:error, :bad_request} = result
    end
  end

  describe "PlugImageProcessing.Operation implementation" do
    test "valid?/1 returns true when operations array has items", %{image: image, config: config} do
      operations_json =
        Jason.encode!([
          %{"operation" => "resize", "params" => %{"width" => 100}}
        ])

      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      assert PlugImageProcessing.Operation.valid?(operation) == true
    end

    test "valid?/1 returns error when operations array is empty", %{image: image, config: config} do
      operations_json = Jason.encode!([])
      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      assert PlugImageProcessing.Operation.valid?(operation) == {:error, :invalid_operations}
    end

    test "process/2 executes single operation successfully", %{image: image, config: config} do
      operations_json =
        Jason.encode!([
          %{"operation" => "resize", "params" => %{"width" => 100}}
        ])

      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
    end

    test "process/2 executes multiple operations in sequence", %{image: image, config: config} do
      operations_json =
        Jason.encode!([
          %{"operation" => "resize", "params" => %{"width" => 200}},
          %{"operation" => "crop", "params" => %{"width" => 100, "height" => 100}}
        ])

      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert %Image{} = result_image
      assert Image.width(result_image) == 100
      assert Image.height(result_image) == 100
    end

    test "process/2 stops on first error and returns error", %{image: image, config: config} do
      operations_json =
        Jason.encode!([
          %{"operation" => "resize", "params" => %{"width" => 100}},
          %{"operation" => "invalid_operation", "params" => %{}},
          %{"operation" => "crop", "params" => %{"width" => 50, "height" => 50}}
        ])

      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      result = PlugImageProcessing.Operation.process(operation, config)

      assert {:error, _} = result
    end

    test "process/2 handles empty operations array", %{image: image, config: config} do
      operations_json = Jason.encode!([])
      params = %{"operations" => operations_json}

      {:ok, operation} = Pipeline.new(image, params, config)

      {:ok, result_image} = PlugImageProcessing.Operation.process(operation, config)

      assert result_image == image
    end
  end
end
