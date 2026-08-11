# نصب روی Railway

1. یک Repository جدید GitHub بساز و محتویات این پوشه را داخل آن قرار بده.
2. در Railway از GitHub همان Repository را Deploy کن.
3. برای Service یک Volume بساز و mount path را `/data` قرار بده.
4. در Networking یک Public Domain بساز.
5. Railway خودش HTTPS را روی Public Domain ارائه می‌کند.
6. پنل از مسیر:
   `https://DOMAIN/panel/`
   قابل دسترسی است.

## اولین ورود

3X-UI رسمی در اولین راه‌اندازی تنظیمات اولیه/اعتبارنامه را مدیریت می‌کند. پس از ورود، نام کاربری و رمز را تغییر بده.

## ساخت WS TLS

در 3X-UI:
- Protocol: VLESS
- Port: 8081
- Network: WS
- Path: `/ws`
- Security داخلی Xray: none

Endpoint عمومی کلاینت:
- Address: Railway Public Domain
- Port: 443
- TLS: on
- SNI: Railway Public Domain
- Network: WS
- Path: `/ws`

TLS در لبه Railway terminate می‌شود و Xray داخلی TLS را terminate نمی‌کند.

## ساخت XHTTP TLS

- Protocol: VLESS
- Port: 8082
- Network: XHTTP
- Path: `/xhttp`

کلاینت:
- Address: Railway Public Domain
- Port: 443
- TLS: on
- SNI: Railway Public Domain
- Network: XHTTP
- Path: `/xhttp`

## gRPC

- Protocol: VLESS
- Port: 8083
- Network: gRPC
- ServiceName: `grpc`

کلاینت:
- Address: Railway Public Domain
- Port: 443
- TLS: on
- SNI: Railway Public Domain
- Network: gRPC
- ServiceName: `grpc`

## HTTP Upgrade

- Protocol: VLESS
- Port: 8084
- Network: HTTPUpgrade
- Path: `/upgrade`

کلاینت:
- Address: Railway Public Domain
- Port: 443
- TLS: on
- SNI: Railway Public Domain
- Network: HTTPUpgrade
- Path: `/upgrade`

## نکته مهم

پورت‌های 8081 تا 8084 پورت‌های داخلی کانتینر هستند. آنها را در Railway Public Networking منتشر نکن.

در این معماری:
Client -> Railway HTTPS :443 -> nginx -> internal Xray port

بنابراین TCP Proxy لازم نیست.


## TCP Proxy for REALITY / RAW

Use a separate internal listener for REALITY.

**Internal service port:** `8443`

In Railway:
`Service → Networking → TCP Proxy → target port 8443`

Railway assigns the external TCP port. The resulting endpoint is generally of the form:

`<generated-tcp-host>:<generated-tcp-port>`

Do not configure the REALITY client to use the normal Railway HTTPS domain on port 443.

In 3X-UI create:
- Protocol: VLESS
- Port: 8443
- Network: TCP
- Security: REALITY
- Flow: xtls-rprx-vision

The TCP Proxy does not share the Nginx `$PORT` listener. This prevents the HTTP/HTTPS listener and raw TCP listener from conflicting.
