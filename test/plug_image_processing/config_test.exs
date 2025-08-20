defmodule PlugImageProcessing.ConfigTest do
  use ExUnit.Case, async: true

  alias PlugImageProcessing.Config

  describe "struct creation" do
    test "creates config with required path" do
      config = %Config{path: "/imageproxy"}

      assert config.path == "/imageproxy"
      assert is_list(config.sources)
      assert is_list(config.operations)
      assert is_list(config.middlewares)
      assert config.onerror == %{}
      assert is_nil(config.url_signature_key)
      assert is_nil(config.allowed_origins)
      assert config.source_url_redirect_operations == []
      assert config.http_client == PlugImageProcessing.Sources.HTTPClient.Hackney
      assert config.http_client_cache == PlugImageProcessing.Sources.HTTPClientCache.Default
      assert config.http_client_timeout == 10_000
      assert config.http_client_max_length == 1_000_000_000
      assert is_nil(config.http_cache_ttl)
    end

    test "creates config with custom values" do
      config = %Config{
        path: "/custom",
        url_signature_key: "secret",
        allowed_origins: ["example.com"],
        http_client_timeout: 5000,
        http_cache_ttl: 3600
      }

      assert config.path == "/custom"
      assert config.url_signature_key == "secret"
      assert config.allowed_origins == ["example.com"]
      assert config.http_client_timeout == 5000
      assert config.http_cache_ttl == 3600
    end

    test "has default sources" do
      config = %Config{path: "/imageproxy"}

      assert PlugImageProcessing.Sources.URL in config.sources
    end

    test "has default operations" do
      config = %Config{path: "/imageproxy"}

      operations_map = Map.new(config.operations)
      assert operations_map[""] == PlugImageProcessing.Operations.Echo
      assert operations_map["crop"] == PlugImageProcessing.Operations.Crop
      assert operations_map["flip"] == PlugImageProcessing.Operations.Flip
      assert operations_map["watermarkimage"] == PlugImageProcessing.Operations.WatermarkImage
      assert operations_map["extract"] == PlugImageProcessing.Operations.ExtractArea
      assert operations_map["resize"] == PlugImageProcessing.Operations.Resize
      assert operations_map["smartcrop"] == PlugImageProcessing.Operations.Smartcrop
      assert operations_map["pipeline"] == PlugImageProcessing.Operations.Pipeline
      assert operations_map["info"] == PlugImageProcessing.Operations.Info
    end

    test "has default middlewares" do
      config = %Config{path: "/imageproxy"}

      assert PlugImageProcessing.Middlewares.SignatureKey in config.middlewares
      assert PlugImageProcessing.Middlewares.AllowedOrigins in config.middlewares
      assert PlugImageProcessing.Middlewares.CacheHeaders in config.middlewares
    end
  end
end
