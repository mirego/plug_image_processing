<div align="center">
  <img src="https://user-images.githubusercontent.com/11348/195426081-7a62709e-3309-4f6a-9740-4ef57d8df5d4.png" width="800" />
  <br /><br />
  Image server as a <a href="https://hex.pm/packages/plug"><code>Plug</code></a>, powered by <a href="https://www.libvips.org/"><code>libvips</code></a>.
  <br /><br />
  <a href="https://github.com/mirego/plug_image_processing/actions/workflows/ci.yml"><img src="https://github.com/mirego/plug_image_processing/actions/workflows/ci.yml/badge.svg" /></a>
  <a href="https://hex.pm/packages/plug_image_processing"><img src="https://img.shields.io/hexpm/v/plug_image_processing.svg" /></a>
</div>

## Usage

### Installation

PlugImageProcessing is published on Hex. Add it to your list of dependencies in `mix.exs`:

```elixir
# mix.exs
def deps do
  [
    {:plug_image_processing, ">= 0.0.1"}
  ]
end
```

Then run mix deps.get to install the package and its dependencies.

To expose a `/imageproxy` route, add the plug in your endpoint, before your router plug, but after `Plug.Parsers`:

```elixir
# lib/my_app_web/endpoint.ex
plug(PlugImageProcessing.Web, path: "/imageproxy")
#...
plug(MyAppWeb.Router)
```

## Features

### Sources

A single source for image is supported for now: the `url` query parameter.

```sh
/imageproxy/resize?url=https://s3.ca-central-1.amazonaws.com/my_image.jpg&width=300
```

It will download the image from the remote location, modify it using libvips and return it to the client.

### Operations

A number of operations exposed by libvips are supported by `PlugImageProcessing`. See the `PlugImageProcessing.Operations.*` module for more details.

### Requests validations

Validations can be added so your endpoint is more secure.

### Signature key

By adding a signature key in your config, a parameter `sign` needs to be included in the URL to validate the payload.
The signature prevent a client to forge a large number of unique requests that would go through the CDN and hitting our server.

```elixir
plug(PlugImageProcessing.Web, url_signature_key: "1234")
```

Then a request path like:

```sh
/imageproxy/resize?url=https://s3.ca-central-1.amazonaws.com/my_image.jpg&width=300&quality=60
```

will fail because the `sign` parameter is not present.

**The HMAC-SHA256 hash is created by taking the URL path (excluding the leading /), the request parameters (alphabetically-sorted and concatenated with & into a string). The hash is then base64url-encoded.**

```elixir
Base.url_encode64(:crypto.mac(:hmac, :sha256, "1234", "resize" <> "quality=60&url=https://s3.ca-central-1.amazonaws.com/my_image.jpg&width=300"))
# => "ku5SCH56vrsqEr-_VRDOFJHqa6AXslh3fpAelPAPoeI="
```

Now this request will succeed!

```sh
/imageproxy/resize?url=https://s3.ca-central-1.amazonaws.com/my_image.jpg&width=300&quality=60&sign=ku5SCH56vrsqEr-_VRDOFJHqa6AXslh3fpAelPAPoeI=
```

## License

`PlugImageProcessing` is © 2022 [Mirego](https://www.mirego.com) and may be freely distributed under the [New BSD license](http://opensource.org/licenses/BSD-3-Clause). See the [`LICENSE.md`](https://github.com/mirego/plug_image_processing/blob/master/LICENSE.md) file.

## About Mirego

[Mirego](https://www.mirego.com) is a team of passionate people who believe that work is a place where you can innovate and have fun. We’re a team of [talented people](https://life.mirego.com) who imagine and build beautiful Web and mobile applications. We come together to share ideas and [change the world](http://www.mirego.org).

We also [love open-source software](https://open.mirego.com) and we try to give back to the community as much as we can.
