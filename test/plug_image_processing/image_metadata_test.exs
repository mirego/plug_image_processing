defmodule PlugImageProcessing.ImageMetadataTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.ImageMetadata

  describe "struct creation" do
    test "creates image metadata with all fields" do
      metadata = %ImageMetadata{
        channels: 3,
        has_alpha: false,
        height: 512,
        width: 512
      }

      assert metadata.channels == 3
      assert metadata.has_alpha == false
      assert metadata.height == 512
      assert metadata.width == 512
    end

    test "creates image metadata with alpha channel" do
      metadata = %ImageMetadata{
        channels: 4,
        has_alpha: true,
        height: 256,
        width: 256
      }

      assert metadata.channels == 4
      assert metadata.has_alpha == true
      assert metadata.height == 256
      assert metadata.width == 256
    end

    test "creates image metadata with nil values" do
      metadata = %ImageMetadata{}

      assert is_nil(metadata.channels)
      assert is_nil(metadata.has_alpha)
      assert is_nil(metadata.height)
      assert is_nil(metadata.width)
    end
  end

  describe "Jason encoding" do
    test "encodes to JSON correctly" do
      metadata = %ImageMetadata{
        channels: 3,
        has_alpha: false,
        height: 512,
        width: 512
      }

      json = Jason.encode!(metadata)
      decoded = Jason.decode!(json)

      assert decoded["channels"] == 3
      assert decoded["has_alpha"] == false
      assert decoded["height"] == 512
      assert decoded["width"] == 512
    end

    test "encodes nil values correctly" do
      metadata = %ImageMetadata{}

      json = Jason.encode!(metadata)
      decoded = Jason.decode!(json)

      assert is_nil(decoded["channels"])
      assert is_nil(decoded["has_alpha"])
      assert is_nil(decoded["height"])
      assert is_nil(decoded["width"])
    end
  end
end
