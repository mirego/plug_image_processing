defmodule PlugImageProcessing.Web do
  use Plug.Builder

  import Plug.Conn

  plug(:cast_config)
  plug(:assign_operation_name)
  plug(:run_middlewares)
  plug(:action)

  def call(conn, opts) do
    conn
    |> put_private(:plug_image_processing_opts, opts)
    |> super(opts)
  end

  def assign_operation_name(conn, _) do
    config_path = conn.private.plug_image_processing_config.path

    if String.starts_with?(conn.request_path, config_path) do
      operation_name = operation_name_from_path(conn.request_path, config_path)
      put_private(conn, :plug_image_processing_operation_name, operation_name)
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

  def action(%{private: %{plug_image_processing_operation_name: operation_name}} = conn, _opts) do
    :telemetry.span(
      [:plug_image_processing, :endpoint],
      %{conn: conn},
      fn -> {halt(process_image(conn, operation_name, retry: true)), %{}} end
    )
  end

  def action(conn, _), do: conn

  def run_middlewares(%{private: %{plug_image_processing_operation_name: _}} = conn, _) do
    PlugImageProcessing.run_middlewares(conn, conn.private.plug_image_processing_config)
  end

  def run_middlewares(conn, _), do: conn

  def cast_config(conn, _) do
    config =
      case conn.private.plug_image_processing_opts do
        {m, f} -> apply(m, f, [])
        {m, f, a} -> apply(m, f, a)
        config when is_list(config) -> config
        config when is_function(config, 0) -> config.()
        config -> raise ArgumentError, "Invalid config, expected either a keyword list, a function reference or a {module, function, args} structure. Got: #{inspect(config)}"
      end

    put_private(conn, :plug_image_processing_config, struct!(PlugImageProcessing.Config, config))
  end

  defp process_image(conn, "info" = operation_name, opts) do
    with {:ok, image, _, _} <- PlugImageProcessing.get_image(conn.params, operation_name, conn.private.plug_image_processing_config),
         {:ok, image_metadata} <- PlugImageProcessing.info(image) do
      send_resp(conn, :ok, Jason.encode!(image_metadata))
    else
      {:redirect, location} ->
        status = if conn.method in ~w(HEAD GET), do: :moved_permanently, else: :temporary_redirect

        conn
        |> put_resp_header("location", location)
        |> send_resp(status, "")
        |> halt()

      {:error, error} ->
        conn
        |> put_resp_header("cache-control", "private, no-cache, no-store, must-revalidate")
        |> handle_error(operation_name, error, opts)
    end
  end

  defp process_image(conn, operation_name, opts) do
    with {:ok, operation_name} <- PlugImageProcessing.cast_operation_name(operation_name, conn.private.plug_image_processing_config),
         {:ok, image, content_type, suffix} <- PlugImageProcessing.get_image(conn.params, operation_name, conn.private.plug_image_processing_config),
         {:ok, image} <- PlugImageProcessing.operations(image, operation_name, conn.params, conn.private.plug_image_processing_config),
         {:ok, image} <- PlugImageProcessing.params_operations(image, conn.params, conn.private.plug_image_processing_config),
         {:ok, binary} <- PlugImageProcessing.write_to_buffer(image, suffix) do
      conn =
        if is_binary(content_type) do
          put_resp_header(conn, "content-type", content_type)
        else
          conn
        end

      send_resp(conn, :ok, binary)
    else
      {:redirect, location} ->
        status = if conn.method in ~w(HEAD GET), do: :moved_permanently, else: :temporary_redirect

        conn
        |> put_resp_header("location", location)
        |> send_resp(status, "")
        |> halt()

      {:error, error} ->
        conn
        |> put_resp_header("cache-control", "private, no-cache, no-store, must-revalidate")
        |> handle_error(operation_name, error, opts)
    end
  end

  defp handle_error(conn, operation_name, error, opts) do
    with true <- Keyword.fetch!(opts, :retry),
         on_error when is_function(on_error) <- Map.get(conn.private.plug_image_processing_config.onerror, conn.params["onerror"]) do
      case on_error.(conn) do
        {:retry, conn} ->
          :telemetry.span(
            [:plug_image_processing, :endpoint, :retry],
            %{conn: conn},
            fn -> {process_image(conn, operation_name, retry: false), %{}} end
          )

        {:halt, conn} ->
          conn

        conn ->
          send_resp(conn, :bad_request, "Bad request: #{inspect(error)}")
      end
    else
      _ ->
        send_resp(conn, :bad_request, "Bad request: #{inspect(error)}")
    end
  end
end
