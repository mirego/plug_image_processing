<div align="center">
  <strong>ImageProxy</strong>
  <br /><br />
  Image server as a plug, powered by libvips.
  <br /><br />
  <a href="https://hex.pm/packages/image_proxy"><img src="https://img.shields.io/hexpm/v/image_proxy.svg" /></a>
</div>

## Usage

### Installation

ImageProxy is published on Hex. Add it to your list of dependencies in `mix.exs`:

```elixir
# mix.exs
def deps do
  [
    {:image_proxy, ">= 0.0.1"}
  ]
end
```

Then run mix deps.get to install the package and its dependencies.

To expose a `/imageproxy` route, add the plug in your endpoint, before your router plug, but after `Plug.Parsers`:

```elixir
# lib/my_app_web/endpoint.ex
plug(ImageProxy.Web, path: "/imageproxy")
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

A number of operations exposed by libvips are supported by `ImageProxy`. See the `ImageProxy.Operations.*` module for more details.

### Requests validations

Validations can be added so your endpoint is more secure.

### Signature key

By adding a signature key in your config, a parameter `sign` needs to be included in the URL to validate the payload.
The signature prevent a client to forge a large number of unique requests that would go through the CDN and hitting our server.

```elixir
plug(ImageProxy.Web, signature_key: "1234")
```

Then a request path like:

```sh
/imageproxy/resize?url=https://s3.ca-central-1.amazonaws.com/my_image.jpg&width=300&quality=60
```

will fail because the `sign` parameter is not present.

**The HMAC-SHA256 hash is created by taking the URL path (including the leading /), the request parameters (alphabetically-sorted and concatenated with & into a string). The hash is then base64url-encoded.**

```elixir
Base.url_encode64(:crypto.mac(:hmac, :sha256, "1234", "/resize" <> "quality=60&url=https://s3.ca-central-1.amazonaws.com/my_image.jpg&width=300"))
# => "O8Xo9xrP0fM67PIWMIRL2hjkD_c5HzzBtRLfpo43ENY="
```

Now this request will succeed!

```sh
/imageproxy/resize?url=https://s3.ca-central-1.amazonaws.com/my_image.jpg&width=300&quality=60&sign=O8Xo9xrP0fM67PIWMIRL2hjkD_c5HzzBtRLfpo43ENY=
```

## License

`ImageProxy` is © 2022 [Mirego](https://www.mirego.com) and may be freely distributed under the [New BSD license](http://opensource.org/licenses/BSD-3-Clause). See the [`LICENSE.md`](https://github.com/simonprev/image_proxy/blob/master/LICENSE.md) file.

## About Mirego

[Mirego](https://www.mirego.com) is a team of passionate people who believe that work is a place where you can innovate and have fun. We’re a team of [talented people](https://life.mirego.com) who imagine and build beautiful Web and mobile applications. We come together to share ideas and [change the world](http://www.mirego.org).

We also [love open-source software](https://open.mirego.com) and we try to give back to the community as much as we can.
