defmodule PlugImageProcessing.Config do
  alias PlugImageProcessing.Middlewares
  alias PlugImageProcessing.Operations
  alias PlugImageProcessing.Sources

  @sources [
    Sources.URL
  ]

  @operations [
    {"crop", Operations.Crop},
    {"flip", Operations.Flip},
    {"watermarkimage", Operations.WatermarkImage},
    {"extract", Operations.ExtractArea},
    {"resize", Operations.Resize},
    {"smartcrop", Operations.Smartcrop},
    {"pipeline", Operations.Pipeline}
  ]

  @middlewares [
    Middlewares.SignatureKey,
    Middlewares.AllowedOrigins,
    Middlewares.CacheHeaders
  ]

  defstruct path: nil,
            sources: @sources,
            operations: @operations,
            middlewares: @middlewares,
            url_signature_key: nil,
            allowed_origins: nil,
            http_cache_ttl: nil
end
