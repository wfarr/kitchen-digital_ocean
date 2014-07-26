# Kitchen::DigitalOcean

A Test Kitchen driver for Digital Ocean API v2.

Forked from the official [test-kitchen/kitchen-digitalocean driver](https://github.com/test-kitchen/kitchen-digitalocean).

## Requirements

* Obviously, this gem depends on Test Kitchen.
* It also depends on `rest_client`, but that'll automatically be handled via RubyGems.
* You also need a Digital Ocean account.
* You need to define the following environment variables:
  * `DIGITALOCEAN_API_TOKEN` -- your API token (requires read+write)
  * `DIGITALOCEAN_SSH_KEYS` -- comma-separated list of SSH key IDs (get from Digital Ocean API)

## Installation and Setup

1. Use ChefDK.
1. Be happy.

```
chef gem install kitchen-digital_ocean
```

In your `.kitchen.yml` or `.kitchen.local.yml`:

``` yaml
---
driver:
  name: digital_ocean

platforms:
  - name: ubuntu-12.10
```

## Additional configuration options

* `username` -- user name to SSH with
* `port` -- SSH port to SSH into
* `private_networking` -- enable private networking on the drpolet
* `region` -- the region to provision the droplet in; you can use the short slugs (eg. `nyc2`)
* `size` -- the size to provision the droplet as; you can use the short slugs (eg. `2gb`)
* `image` -- the image to provision the droplet with; you can use the short slugs
* `server_name` -- you probably want to leave this alone
* `digitalocean_api_token` -- you can set this, but seriously use the environment variable above
* `digitalocean_ssh_keys` -- you can set this, but seriously use the environment variable above

For more details, see the [Digital Ocean API documentation](https://developers.digitalocean.com/).
