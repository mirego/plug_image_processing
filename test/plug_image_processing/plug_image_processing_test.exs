defmodule PlugImageProcessingTest do
  use ExUnit.Case, async: true

  setup do
    config = [
      path: "/imageproxy"
    ]

    {:ok, config: config}
  end

  describe "generate_url" do
    test "valid", %{config: config} do
      url = PlugImageProcessing.generate_url("http://example.com", config, :resize, %{url: "http://bucket.com/test.jpg", width: 10})
      uri = URI.parse(url)
      query_params = Enum.to_list(URI.query_decoder(uri.query))

      assert uri.host === "example.com"
      assert uri.path === "/imageproxy/resize"
      assert {"width", "10"} in query_params
      assert {"url", "http://bucket.com/test.jpg"} in query_params
    end

    test "valid with signature", %{config: config} do
      url_signature_key = "12345"
      config = Keyword.put(config, :url_signature_key, url_signature_key)

      url = PlugImageProcessing.generate_url("http://example.com", config, :resize, %{url: "http://bucket.com/test.jpg", width: 10})

      assert URI.decode_query(URI.parse(url).query)["sign"] === generate_signature_from_url(url_signature_key, "resizeurl=http%3A%2F%2Fbucket.com%2Ftest.jpg&width=10")
    end
  end

  defp generate_signature_from_url(url_signature_key, url) do
    Base.url_encode64(:crypto.mac(:hmac, :sha256, url_signature_key, url))
  end
end
