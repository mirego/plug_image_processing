defmodule ImageProxy.Web do
  use Plug.Builder, copy_opts_to_assign: :image_proxy_opts

  import Plug.Conn

  plug(:cast_config)
  plug(:assign_operation_name)
  plug(:validate)
  plug(:action)

  def assign_operation_name(conn, _) do
    config_path = conn.assigns.image_proxy_config.path

    if String.starts_with?(conn.request_path, config_path) do
      operation_name = operation_name_from_path(conn.request_path, config_path)
      assign(conn, :image_proxy_operation_name, operation_name)
    else
      conn
    end
  end

  defp operation_name_from_path(request_path, config_path) do
    request_path
    |> String.trim_leading(config_path)
    |> String.trim_leading("/")
    |> String.split("/", parts: 2)
    |> List.first()
  end

  def action(%{assigns: %{image_proxy_operation_name: operation_name}} = conn, _opts) do
    :telemetry.span(
      [:image_proxy, :endpoint],
      %{conn: conn},
      fn -> {halt(process_image(conn, operation_name)), %{}} end
    )
  end

  def action(conn, _), do: conn

  def validate(%{assigns: %{image_proxy_operation_name: _}} = conn, _) do
    ImageProxy.validate_conn(conn, conn.assigns.image_proxy_config)
  end

  def validate(conn, _), do: conn

  def cast_config(conn, _) do
    config =
      case conn.assigns.image_proxy_opts do
        {m, f, a} -> apply(m, f, a)
        config when is_list(config) -> config
        config when is_function(config, 0) -> config.()
        config -> raise ArgumentError, "Invalid config, expected either a keyword list, a function reference or a {module, function, args} structure. Got: #{inspect(config)}"
      end

    assign(conn, :image_proxy_config, struct!(ImageProxy.Config, config))
  end

  defp process_image(conn, operation_name) do
    with {:ok, operation_name} <- ImageProxy.cast_operation_name(operation_name),
         {:ok, image, suffix} <- ImageProxy.get_image(conn.params),
         {:ok, image} <- ImageProxy.operations(image, operation_name, conn.params),
         {:ok, image} <- ImageProxy.params_operations(image, conn.params) do
      image
      |> ImageProxy.write_to_stream(suffix)
      |> send_chunk(conn)
    else
      {:error, error} ->
        send_resp(conn, 400, "Bad request: #{inspect(error)}")
    end
  end

  defp send_chunk(stream, conn) do
    conn = send_chunked(conn, 200)

    Enum.reduce_while(stream, conn, fn chunk, conn ->
      case chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)
  end
end
