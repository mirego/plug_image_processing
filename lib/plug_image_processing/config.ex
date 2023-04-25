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

  @enforce_keys ~w(path)a
  defstruct path: nil,
            sources: @sources,
            operations: @operations,
            middlewares: @middlewares,
            onerror: %{},
            url_signature_key: nil,
            allowed_origins: nil,
            source_url_redirect_operations: [],
            http_client_cache: PlugImageProcessing.Sources.HTTPClientCache.Default,
            http_client: PlugImageProcessing.Sources.HTTPClient.Hackney,
            http_client_timeout: 10_000,
            http_client_max_length: 1_000_000_000,
            http_cache_ttl: nil

  @type t :: %__MODULE__{
          path: String.t() | nil,
          middlewares: list(module()),
          operations: list({String.t(), module()}),
          sources: list(module()),
          source_url_redirect_operations: list(String.t()),
          onerror: %{},
          http_client: module(),
          url_signature_key: String.t() | nil,
          allowed_origins: list(String.t()) | nil,
          http_cache_ttl: non_neg_integer() | nil,
          http_client_timeout: non_neg_integer(),
          http_client_max_length: non_neg_integer()
        }
end
