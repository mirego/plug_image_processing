defprotocol PlugImageProcessing.Source do
  @spec get_image(struct(), PlugImageProcessing.Config.t()) :: {:ok, PlugImageProcessing.image(), String.t() | nil, String.t()} | {:error, atom()}
  def get_image(source, config)

  @spec cast(struct(), map()) :: struct() | boolean()
  def cast(source, params)
end
