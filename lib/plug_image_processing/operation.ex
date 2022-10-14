defprotocol PlugImageProcessing.Operation do
  @typep error :: {:error, atom()}
  @type t :: struct()

  @spec valid?(t()) :: boolean() | error()
  def valid?(operation)

  @spec process(t(), PlugImageProcessing.Config.t()) :: {:ok, PlugImageProcessing.image()} | error()
  def process(operation, config)
end
