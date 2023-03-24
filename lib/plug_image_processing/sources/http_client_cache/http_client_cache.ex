defmodule PlugImageProcessing.Sources.HTTPClientCache do
  @typep source :: PlugImageProcessing.Sources.URL.t()
  @callback invalid_source?(source()) :: boolean()
  @callback fetch_source(source()) :: nil | {:ok, binary(), Keyword.t()}
  @callback put_source(source(), any()) :: :ok
end
