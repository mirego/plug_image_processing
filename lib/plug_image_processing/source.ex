defprotocol PlugImageProcessing.Source do
  @spec get_image(struct(), String.t(), PlugImageProcessing.Config.t()) ::
          {:ok, PlugImageProcessing.image(), String.t() | nil, String.t()} | {:error, atom()} | {:redirect, String.t()}
  def get_image(source, operation_name, config)

  @spec cast(struct(), map()) :: struct() | boolean()
  def cast(source, params)
end
