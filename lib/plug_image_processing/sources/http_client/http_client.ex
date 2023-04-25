defmodule PlugImageProcessing.Sources.HTTPClient do
  @callback get(url :: String.t(), max_length :: non_neg_integer()) :: {:ok, binary(), Keyword.t()} | {:http_error, any()} | {:error, any()}
end
