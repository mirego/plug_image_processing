defprotocol PlugImageProcessing.Source do
  def get_image(source)
  def cast(source, params)
end
