defmodule PlugImageProcessing.Sources.HTTPClient.Hackney do
  @moduledoc false
  @behaviour PlugImageProcessing.Sources.HTTPClient

  def get(url, max_length) do
    with {:ok, 200, headers, body} when is_binary(body) <- :hackney.get(url, [], <<>>, follow_redirect: true),
         true <- byte_size(body) <= max_length do
      {:ok, body, headers}
    else
      {:ok, status, _, _body} ->
        {:http_error, status}

      false ->
        {:error, :body_too_large}

      {:error, error} ->
        {:error, error}

      error ->
        {:error, error}
    end
  end
end
