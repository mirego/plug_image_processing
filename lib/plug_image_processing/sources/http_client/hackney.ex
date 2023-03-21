defmodule PlugImageProcessing.Sources.HTTPClient.Hackney do
  @behaviour PlugImageProcessing.Sources.HTTPClient

  def get(url) do
    with {:ok, 200, headers, client_reference} <- :hackney.get(url, [], <<>>, follow_redirect: true),
         {:ok, body} when is_binary(body) <- :hackney.body(client_reference) do
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
