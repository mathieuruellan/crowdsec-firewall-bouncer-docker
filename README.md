# CrowdSec Firewall Bouncer Docker

A minimal Docker image for the [CrowdSec Firewall Bouncer](https://docs.crowdsec.net/docs/bouncers/firewall-bouncer/) with nftables support, based on Debian bookworm-slim.

## Usage

Create a config file:

```yaml
# crowdsec-firewall-bouncer.yaml
api_url: http://192.168.1.6:8580
api_key: your-bouncer-api-key
mode: nftables
update_frequency: 10s
daemonize: false

log_level: info
log_media: stdout

nftables:
  enabled: true
  ipv4_table: crowdsec
  ipv6_table: crowdsec6
  ipv4_chain: crowdsec-chain
  ipv6_chain: crowdsec-chain
```

Generate a bouncer key with `cscli bouncers add <name>` on your CrowdSec LAPI.

Run with the host network so nftables rules apply to the host:

```bash
docker run -d --name crowdsec-firewall-bouncer \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -v /path/to/crowdsec-firewall-bouncer.yaml:/etc/crowdsec/crowdsec-firewall-bouncer.yaml:ro \
  ghcr.io/mathieuruellan/crowdsec-firewall-bouncer-docker:latest
```

The image ships with a default config at `/etc/crowdsec/crowdsec-firewall-bouncer.yaml` that you can override by mounting your own file.

## Build

```bash
docker build -t crowdsec-firewall-bouncer .
```

## Requirements

- Host with nftables and privileged container support (`NET_ADMIN`, `NET_RAW`)

## References

- [CrowdSec Documentation](https://docs.crowdsec.net/)
- [CrowdSec Firewall Bouncer](https://docs.crowdsec.net/docs/bouncers/firewall-bouncer/)
