defprotocol PlugImageProcessing.Middleware do
  def run(middleware, conn)
  def enabled?(middleware, conn)
end
