defmodule PlugImageProcessing.Sources.HTTPClient do
  @callback get(url :: String.t()) :: {:ok, binary(), Keyword.t()} | {:http_error, any()} | {:error, any()}
end
