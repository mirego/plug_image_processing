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
  end
end
