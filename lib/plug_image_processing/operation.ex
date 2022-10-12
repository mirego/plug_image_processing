defprotocol PlugImageProcessing.Operation do
  def valid?(operation)
  def process(operation, config)
end
