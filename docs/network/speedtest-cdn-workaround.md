# Temporary SpeedTest.cn CDN workaround

This workaround is local to the affected network. It is not a globally valid or permanent DNS record, and is not evidence that the campus network itself is broken.

## Evidence and scope

For `https://www.speedtest.cn/`, the regional CDN address `1.82.232.57` timed out during TCP connection establishment, while `1.194.31.54` returned HTTP 200 from both the router and the desktop. Public and campus DNS answers could alternate between those addresses, so changing only the upstream resolver was not reliable.

The temporary mapping preserves the original HTTPS hostname, SNI and certificate verification. No TLS checks are disabled. Clash Verge's observed connection chain was `DIRECT` through the domestic-sites group; the workaround does not intentionally route the speed test through an overseas proxy.

The page and its 15 top-level script/stylesheet resources were fetched successfully. The full browser interaction and actual bandwidth test were not exercised. Do not infer that every dynamically selected test endpoint will use the same route.

## Desktop configuration

The chezmoi source `dot_local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Merge.yaml` deploys to the effective Clash Verge global enhancement file:

```text
~/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Merge.yaml
```

It contains this temporary addition alongside the existing enhancement settings:

```yaml
hosts:
  www.speedtest.cn: 1.194.31.54
```

The legacy `~/.config/clash-verge` directory is not the effective data directory for this installation. Keep subscription URLs, credentials, full app settings and generated runtime YAML out of this repository.

The global enhancement script currently adds internal hosts and other rules. Before deploying on a different machine, merge the site-specific entry with that machine's existing global enhancement rather than overwriting it blindly. A Clash Verge restart or configuration regeneration is needed for the running core to adopt the change.

## Router configuration

The router's matching dnsmasq UCI rule is not automatically deployed by chezmoi:

```text
address=/www.speedtest.cn/1.194.31.54
```

To reproduce it manually on an OpenWrt/ImmortalWrt router, back up `/etc/config/dhcp`, check for an existing conflicting `address` entry, then add the rule once:

```sh
uci add_list 'dhcp.@dnsmasq[0].address=/www.speedtest.cn/1.194.31.54'
uci commit dhcp
/etc/init.d/dnsmasq reload
```

Preserve all unrelated DHCP reservations, upstream resolvers and firewall settings. This is not a reason to enable or disable a proxy service.

## Validation

After configuration regeneration, inspect the effective Clash Verge `hosts` entry and connection chain. On the router, check both DNS and an ordinary HTTPS request without a command-line IP override:

```sh
nslookup www.speedtest.cn 127.0.0.1
curl --noproxy '*' --connect-timeout 5 --max-time 15 \
  -sS -o /dev/null \
  -w 'HTTP=%{http_code} IP=%{remote_ip} seconds=%{time_total}\n' \
  https://www.speedtest.cn/
```

## Maintenance and rollback

A CDN address can change or become unavailable. Periodically compare public/campus DNS answers and HTTPS reachability before retaining this mapping. It is a temporary workaround, not a permanent source of truth.

Remove only the `www.speedtest.cn` mapping from the Clash Verge enhancement file, regenerate/restart its configuration, and remove only the matching router rule:

```sh
uci -q del_list 'dhcp.@dnsmasq[0].address=/www.speedtest.cn/1.194.31.54'
uci commit dhcp
/etc/init.d/dnsmasq reload
```

Avoid restoring whole configuration backups over later unrelated changes. Browser DNS/connection caches may need to be refreshed after applying or removing the workaround.
