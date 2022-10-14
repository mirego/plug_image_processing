defprotocol PlugImageProcessing.Middleware do
  @type t :: struct()

  @spec run(t(), Plug.Conn.t()) :: Plug.Conn.t()
  def run(middleware, conn)

  @spec enabled?(t(), Plug.Conn.t() | nil) :: boolean()
  def enabled?(middleware, conn)
end
