# ddnuts

A lightweight tool for updating cloudflare DNS reords (DDNS).

```
ddnuts ddnuts.com zone_id=... api_token=...
```

> [!TIP]
> Use `ddnuts help` to get more info.

## Installation

Download the executable:

| Linux ([amd64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-linux-amd64), [arm64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-linux-arm64)) | macOS ([amd64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-macos-amd64), [arm64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-macos-amd64)) | Windows ([amd64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-windows-amd64.exe), [arm64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-windows-amd64.exe)) |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |

Download the package:

| Debian ([amd64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-linux-amd64.deb), [arm64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-linux-arm64.deb)) |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |

> [!NOTE]
> The ddnuts package will start a system service, and automatically create a config file at the default location.

## Conguration

By default, the location of the config file is `/etc/ddnuts.conf` on Linux and macOS, and next to the executable on Windows. You can specify the path of the config file by passing the `config=<path>` option.

To add a domain to update, specify the domain and options:

```
# [ <domain> ]
# zone_id = ...
# api_token = ...
# interval = ...
```

You can also set global options by putting them before any domain:

```
# zone_id = ...
# api_token = ...
#
# [ <domain> ]
# zone_id = ...
# api_token = ...
```

- `<zone_id>` The zone where the domain belongs to. (Required)
- `<api_token>` Your API Token that have access to the zone. (Required)
- `<interval>` The interval between each update.
