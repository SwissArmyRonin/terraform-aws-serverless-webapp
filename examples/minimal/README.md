# Minimal example

This deploys the premaed client and front-end to AWS. Please note that the client has a pre-baked URL to the back-end that is XXX.

Before applying the example template, look for the following snippet in `client/static/js/main.706285c8.chunk.js` and fix the URL to `api.ZONE_NAME` where `ZONE_NAME`is replaced with whatever you put in `${var.zone_name}`:

```js
m.a.get("https://api.isntall.net/api/todos")
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| region | The AWS target region | string | `"eu-west-1"` | no |
| zone\_name | The top level domain that will host the subdomains used for the front- and back-end | string | `"isntall.net"` | no |

