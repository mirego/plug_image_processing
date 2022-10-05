defprotocol ImageProxy.Operation do
  def valid?(operation)
  def process(operation)
end
