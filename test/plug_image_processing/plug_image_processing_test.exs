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

      assert url === "http://example.com/imageproxy/resize?url=http%3A%2F%2Fbucket.com%2Ftest.jpg&width=10"
    end
  end
end
