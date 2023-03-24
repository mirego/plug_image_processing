defmodule PlugImageProcessing.Sources.HTTPClientCache.Default do
  @behaviour PlugImageProcessing.Sources.HTTPClientCache

  def invalid_source?(_source), do: false
  def fetch_source(_source), do: nil
  def put_source(_source, _), do: :ok
end
