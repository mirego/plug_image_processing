defmodule PlugImageProcessing.Web do
  use Plug.Builder, copy_opts_to_assign: :plug_image_processing_opts

  import Plug.Conn

  plug(:cast_config)
  plug(:assign_operation_name)
  plug(:run_middlewares)
  plug(:action)

  def assign_operation_name(conn, _) do
    config_path = conn.assigns.plug_image_processing_config.path

    if String.starts_with?(conn.request_path, config_path) do
      operation_name = operation_name_from_path(conn.request_path, config_path)
      assign(conn, :plug_image_processing_operation_name, operation_name)
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

  def action(%{assigns: %{plug_image_processing_operation_name: operation_name}} = conn, _opts) do
    :telemetry.span(
      [:plug_image_processing, :endpoint],
      %{conn: conn},
      fn -> {halt(process_image(conn, operation_name)), %{}} end
    )
  end

  def action(conn, _), do: conn

  def run_middlewares(%{assigns: %{plug_image_processing_operation_name: _}} = conn, _) do
    PlugImageProcessing.run_middlewares(conn, conn.assigns.plug_image_processing_config)
  end

  def run_middlewares(conn, _), do: conn

  def cast_config(conn, _) do
    config =
      case conn.assigns.plug_image_processing_opts do
        {m, f} -> apply(m, f, [])
        {m, f, a} -> apply(m, f, a)
        config when is_list(config) -> config
        config when is_function(config, 0) -> config.()
        config -> raise ArgumentError, "Invalid config, expected either a keyword list, a function reference or a {module, function, args} structure. Got: #{inspect(config)}"
      end

    assign(conn, :plug_image_processing_config, struct!(PlugImageProcessing.Config, config))
  end

  defp process_image(conn, operation_name) do
    with {:ok, operation_name} <- PlugImageProcessing.cast_operation_name(operation_name, conn.assigns.plug_image_processing_config),
         {:ok, image, suffix} <- PlugImageProcessing.get_image(conn.params, conn.assigns.plug_image_processing_config),
         {:ok, image} <- PlugImageProcessing.operations(image, operation_name, conn.params, conn.assigns.plug_image_processing_config),
         {:ok, image} <- PlugImageProcessing.params_operations(image, conn.params, conn.assigns.plug_image_processing_config) do
      image
      |> PlugImageProcessing.write_to_stream(suffix)
      |> send_chunk(conn)
    else
      {:error, error} ->
        conn
        |> delete_resp_header("cache-control")
        |> send_resp(:bad_request, "Bad request: #{inspect(error)}")
    end
  end

  defp send_chunk(stream, conn) do
    conn = send_chunked(conn, :ok)

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
