# ddnuts

A lightweight tool for updating cloudflare DNS reords (DDNS).

```
ddnuts ddnuts.com zone_id=... api_token=...
```

> [!NOTE]
> Use `ddnuts help` to get more info.

## Installation

Download the executable:

| Linux ([amd64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-linux-amd64), [arm64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-linux-arm64)) | macOS ([amd64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-macos-amd64), [arm64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-macos-amd64)) | Windows ([amd64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-windows-amd64.exe), [arm64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-windows-amd64.exe)) |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |

Download the package:

| Debian ([amd64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-linux-amd64.deb), [arm64](https://github.com/LmanTW/ddnuts/releases/latest/download/ddnuts-linux-arm64.deb)) |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |

> [!TIP]
> The ddnuts package will start a system service, and automatically create a config file at the default location.

## Conguration

By default, the location of the config file is `/etc/ddnuts.conf` on Linux and macOS, and next to the executable on Windows. You can specify the path of the config file by passing the `config=<path>` option. You can learn more about how to configure ddnuts in the config file.
