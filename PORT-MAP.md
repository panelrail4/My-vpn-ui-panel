# Railway port map

| Function | Internal service port | Public endpoint |
|---|---:|---|
| Railway HTTPS / 3X-UI + WS | `$PORT` | `https://<railway-domain>:443` |
| XHTTP | `$PORT` via `/xhttp` | `https://<railway-domain>:443/xhttp` |
| gRPC | `$PORT` via `/grpc` | `https://<railway-domain>:443/grpc` |
| HTTP Upgrade | `$PORT` via `/upgrade` | `https://<railway-domain>:443/upgrade` |
| VLESS TCP + REALITY | `8443` | Railway TCP Proxy generated host/port |

The TCP Proxy external port is assigned by Railway and must be read from the Networking panel.
