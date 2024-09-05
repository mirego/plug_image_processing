defmodule PlugImageProcessing.Options do
  @moduledoc false
  alias PlugImageProcessing.Sources.URL

  def build(options) do
    options
    |> Enum.map(fn
      {key, {:ok, value}} -> {key, value}
      {key, value} -> {key, value}
      _ -> {nil, nil}
    end)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  def encode_suffix(options) do
    options = Enum.map_join(options, ",", fn {key, value} -> "#{key}=#{value}" end)
    if options === "", do: options, else: "[#{options}]"
  end

  def cast_direction(value, default \\ nil)
  def cast_direction("x", _default), do: {:ok, :VIPS_DIRECTION_HORIZONTAL}
  def cast_direction("y", _default), do: {:ok, :VIPS_DIRECTION_VERTICAL}
  def cast_direction(_, default), do: {:ok, default}

  def cast_boolean(value, default \\ nil)
  def cast_boolean("true", _default), do: {:ok, true}
  def cast_boolean("false", _default), do: {:ok, false}
  def cast_boolean(_, default), do: {:ok, default}

  def cast_remote_image(url, operation_name, config) do
    with %URL{} = source <- PlugImageProcessing.Source.cast(%URL{}, %{"url" => url}),
         {:ok, image, _, _} <- PlugImageProcessing.Source.get_image(source, operation_name, config) do
      {:ok, image}
    end
  end

  def cast_integer(value, default \\ nil)

  def cast_integer(nil, default), do: {:ok, default}

  def cast_integer(value, _) when is_integer(value), do: {:ok, value}

  def cast_integer(value, _) do
    case Integer.parse(value) do
      {value, _} -> {:ok, value}
      _ -> {:error, :bad_request}
    end
  end

  def cast_json(nil), do: {:error, :bad_request}

  def cast_json(operations) do
    case Jason.decode(operations) do
      {:ok, operations} -> {:ok, operations}
      _ -> {:error, :bad_request}
    end
  end
end
