defprotocol PlugImageProcessing.Middleware do
  @moduledoc """
  Protocol for implementing middleware in the image processing pipeline.

  Middleware can be used to add security checks, modify headers, validate
  requests, or perform any other processing on the connection before or
  after image operations.
  """

  @type t :: struct()

  @doc """
  Executes the middleware logic on the connection.

  This function should process the connection and return a potentially
  modified connection. It may halt the connection if validation fails.

  ## Parameters
    - `middleware` - The middleware struct containing configuration
    - `conn` - The Plug.Conn struct to process

  ## Returns
    - Modified Plug.Conn struct (may be halted)
  """
  @spec run(t(), Plug.Conn.t()) :: Plug.Conn.t()
  def run(middleware, conn)

  @doc """
  Determines if this middleware should be enabled for the given connection.

  This allows conditional activation of middleware based on configuration
  or request parameters.

  ## Parameters
    - `middleware` - The middleware struct containing configuration
    - `conn` - The Plug.Conn struct to check (may be nil during initialization)

  ## Returns
    - `true` if the middleware should run, `false` otherwise
  """
  @spec enabled?(t(), Plug.Conn.t() | nil) :: boolean()
  def enabled?(middleware, conn)
end
