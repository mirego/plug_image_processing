defprotocol ImageProxy.ConnValidation do
  def validate(plug_security, conn)
  def enabled?(plug_security, conn)
end
