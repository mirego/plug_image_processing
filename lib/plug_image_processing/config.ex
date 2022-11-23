defmodule PlugImageProcessing.Config do
  alias PlugImageProcessing.Middlewares
  alias PlugImageProcessing.Operations
  alias PlugImageProcessing.Sources

  @sources [
    Sources.URL
  ]

  @operations [
    {"", Operations.Echo},
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

  @type t :: %__MODULE__{
          path: String.t() | nil,
          middlewares: list(module()),
          operations: list({String.t(), module()}),
          sources: list(module()),
          url_signature_key: String.t() | nil,
          allowed_origins: list(String.t()) | nil,
          http_cache_ttl: non_neg_integer() | nil
        }
end
