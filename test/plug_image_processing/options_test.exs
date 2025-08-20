defmodule PlugImageProcessing.OptionsTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config
  alias PlugImageProcessing.Options

  defmodule HTTPMock do
    @moduledoc false
    @behaviour PlugImageProcessing.Sources.HTTPClient

    @image File.read!("test/support/image.jpg")

    def get("http://example.org/valid.jpg", _), do: {:ok, @image, [{"Content-type", "image/jpg"}]}
    def get("http://example.org/404.jpg", _), do: {:error, "404 Not found"}
  end

  setup do
    config = %Config{path: "/imageproxy", http_client: HTTPMock}
    {:ok, config: config}
  end

  describe "build/1" do
    test "builds options from list with ok tuples" do
      options = [
        {"width", {:ok, 100}},
        {"height", {:ok, 200}},
        {"quality", {:ok, 80}}
      ]

      result = Options.build(options)

      assert result == [{"width", 100}, {"height", 200}, {"quality", 80}]
    end

    test "builds options from list with direct values" do
      options = [
        {"width", 100},
        {"height", 200},
        {"quality", 80}
      ]

      result = Options.build(options)

      assert result == [{"width", 100}, {"height", 200}, {"quality", 80}]
    end

    test "builds options from mixed list" do
      options = [
        {"width", {:ok, 100}},
        {"height", 200},
        {"quality", {:ok, 80}}
      ]

      result = Options.build(options)

      assert result == [{"width", 100}, {"height", 200}, {"quality", 80}]
    end

    test "filters out nil values" do
      options = [
        {"width", {:ok, 100}},
        {"height", nil},
        {"quality", {:ok, 80}},
        {"format", nil}
      ]

      result = Options.build(options)

      assert result == [{"width", 100}, {"quality", 80}]
    end

    test "filters out invalid entries" do
      options = [
        {"width", {:ok, 100}},
        :invalid_entry,
        {"height", 200},
        nil
      ]

      result = Options.build(options)

      assert result == [{"width", 100}, {"height", 200}]
    end

    test "handles empty list" do
      options = []

      result = Options.build(options)

      assert result == []
    end
  end

  describe "encode_suffix/1" do
    test "encodes options to suffix format" do
      options = [{"width", 100}, {"height", 200}, {"quality", 80}]

      result = Options.encode_suffix(options)

      assert result == "[width=100,height=200,quality=80]"
    end

    test "encodes single option" do
      options = [{"width", 100}]

      result = Options.encode_suffix(options)

      assert result == "[width=100]"
    end

    test "returns empty string for empty options" do
      options = []

      result = Options.encode_suffix(options)

      assert result == ""
    end

    test "handles options with string values" do
      options = [{"format", "jpg"}, {"gravity", "center"}]

      result = Options.encode_suffix(options)

      assert result == "[format=jpg,gravity=center]"
    end
  end

  describe "cast_direction/2" do
    test "casts 'x' to horizontal direction" do
      assert Options.cast_direction("x") == {:ok, :VIPS_DIRECTION_HORIZONTAL}
    end

    test "casts 'y' to vertical direction" do
      assert Options.cast_direction("y") == {:ok, :VIPS_DIRECTION_VERTICAL}
    end

    test "returns default for unknown value" do
      assert Options.cast_direction("unknown") == {:ok, nil}
      assert Options.cast_direction("unknown", :default) == {:ok, :default}
    end

    test "returns default for nil value" do
      assert Options.cast_direction(nil) == {:ok, nil}
      assert Options.cast_direction(nil, :default) == {:ok, :default}
    end
  end

  describe "cast_boolean/2" do
    test "casts 'true' to boolean true" do
      assert Options.cast_boolean("true") == {:ok, true}
    end

    test "casts 'false' to boolean false" do
      assert Options.cast_boolean("false") == {:ok, false}
    end

    test "returns default for unknown value" do
      assert Options.cast_boolean("unknown") == {:ok, nil}
      assert Options.cast_boolean("unknown", :default) == {:ok, :default}
    end

    test "returns default for nil value" do
      assert Options.cast_boolean(nil) == {:ok, nil}
      assert Options.cast_boolean(nil, :default) == {:ok, :default}
    end
  end

  describe "cast_remote_image/3" do
    test "casts valid remote image URL", %{config: config} do
      {:ok, image} = Options.cast_remote_image("http://example.org/valid.jpg", "test", config)

      assert %Vix.Vips.Image{} = image
    end

    test "returns error for invalid remote image URL", %{config: config} do
      result = Options.cast_remote_image("http://example.org/404.jpg", "test", config)

      assert {:error, :invalid_file} = result
    end

    test "returns error for nil URL", %{config: config} do
      result = Options.cast_remote_image(nil, "test", config)

      assert result == false
    end
  end

  describe "cast_integer/2" do
    test "casts nil to default value" do
      assert Options.cast_integer(nil) == {:ok, nil}
      assert Options.cast_integer(nil, 100) == {:ok, 100}
    end

    test "returns integer value as-is" do
      assert Options.cast_integer(42) == {:ok, 42}
      assert Options.cast_integer(0) == {:ok, 0}
      assert Options.cast_integer(-10) == {:ok, -10}
    end

    test "parses string integers" do
      assert Options.cast_integer("42") == {:ok, 42}
      assert Options.cast_integer("0") == {:ok, 0}
      assert Options.cast_integer("-10") == {:ok, -10}
    end

    test "parses string integers with trailing characters" do
      assert Options.cast_integer("42px") == {:ok, 42}
      assert Options.cast_integer("100%") == {:ok, 100}
    end

    test "returns error for invalid strings" do
      assert Options.cast_integer("invalid") == {:error, :bad_request}
      assert Options.cast_integer("") == {:error, :bad_request}
      assert Options.cast_integer("abc123") == {:error, :bad_request}
    end
  end

  describe "cast_json/1" do
    test "returns error for nil" do
      assert Options.cast_json(nil) == {:error, :bad_request}
    end

    test "parses valid JSON" do
      json = Jason.encode!(%{"key" => "value", "number" => 42})

      assert Options.cast_json(json) == {:ok, %{"key" => "value", "number" => 42}}
    end

    test "parses JSON array" do
      json = Jason.encode!([1, 2, 3])

      assert Options.cast_json(json) == {:ok, [1, 2, 3]}
    end

    test "returns error for invalid JSON" do
      assert Options.cast_json("{invalid json}") == {:error, :bad_request}
      assert Options.cast_json("not json at all") == {:error, :bad_request}
      assert Options.cast_json("{") == {:error, :bad_request}
    end

    test "handles empty JSON objects and arrays" do
      assert Options.cast_json("{}") == {:ok, %{}}
      assert Options.cast_json("[]") == {:ok, []}
    end
  end
end
