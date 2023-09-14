defprotocol PlugImageProcessing.Info do
  @typep error :: {:error, atom()}
  @type t :: struct()

  @spec process(t()) :: {:ok, PlugImageProcessing.ImageMetadata.t()} | error()
  def process(operation)
end
