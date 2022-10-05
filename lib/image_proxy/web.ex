defmodule ImageProxy.Web do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(%{request_path: "/imageproxy/" <> operation_name} = conn, _opts) do
    metadata = %{conn: conn}

    conn =
      :telemetry.span(
        [:image_proxy, :endpoint],
        metadata,
        fn -> {process_image(conn, operation_name), %{}} end
      )

    halt(conn)
  end

  def call(conn, _opts), do: conn

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
