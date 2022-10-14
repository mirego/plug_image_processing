defprotocol PlugImageProcessing.Source do
  @spec get_image(struct()) :: {:ok, PlugImageProcessing.image(), String.t() | nil, String.t()} | {:error, atom()}
  def get_image(source)

  @spec cast(struct(), map()) :: struct() | boolean()
  def cast(source, params)
end
