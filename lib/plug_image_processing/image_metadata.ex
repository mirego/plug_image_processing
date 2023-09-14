defmodule PlugImageProcessing.ImageMetadata do
  @derive Jason.Encoder
  defstruct channels: nil, has_alpha: nil, height: nil, width: nil

  @type t :: %__MODULE__{
          channels: number(),
          has_alpha: boolean(),
          height: number(),
          width: number()
        }
end
