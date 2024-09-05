defmodule PlugImageProcessing.Sources.HTTPClient.Hackney do
  @moduledoc false
  @behaviour PlugImageProcessing.Sources.HTTPClient

  def get(url, max_length) do
    with {:ok, 200, headers, client_reference} <- :hackney.get(url, [], <<>>, follow_redirect: true),
         {:ok, body} when is_binary(body) <- :hackney.body(client_reference, max_length) do
      {:ok, body, headers}
    else
      {:ok, status, _, _} ->
        {:http_error, status}

      {:error, error} ->
        {:error, error}

      error ->
        {:error, error}
    end
  end
end
