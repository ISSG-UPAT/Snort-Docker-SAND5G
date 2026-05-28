# Snort Docker Image

## Description of the SAND5G Project

5G -and beyond- networks provide a strong foundation for EU's digital transformation and are becoming one of the Union's key assets to compete in the global market.

Securing 5G networks and the services running on top of them requires high quality technical security solutions and also strong collaboration at the operational level.

https://sand5g-project.eu

<img src="https://sand5g-project.eu/wp-content/uploads/2024/06/SAND5G-logo-600x137.png" alt="SAND5G" width="300" height="68">

## What it is

This is a Docker image for Snort, a popular open-source network intrusion detection system (NIDS) and Intrusion Prevention System. This image is designed to be easy to use and configure, allowing you to quickly set up Snort in a Docker container.

It is built from sources and releases of the Snort tool and has added functionalities for 5G network monitoring.

The current image on DockerHub is of [snort v3.9.1.0](https://github.com/snort3/snort3/tree/3.9.1.0)

## How to use

### Docker compose command

```bash
docker compose up
```

### Docker compose file

```yaml
services:
  snort3:
    image: issgupat/snort-docker-sand5g:latest
    hostname: snort3
    network_mode: "host"
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - custom_data:/home/snorty/custom
      - alerts_data:/home/snorty/alerts
      - /etc/localtime:/etc/localtime:ro
    environment:
      - TZ=Europe/Athens
      # IDS_MODE selects which 5G interface/ruleset to activate:
      #   n2     — NGAP/SCTP  port 38412  (N2: AMF ↔ gNB)
      #   n3     — GTP-U/UDP  port 2152   (N3: gNB ↔ UPF) + ogstun FORWARD
      #   n4     — PFCP/UDP   port 8805   (N4: SMF ↔ UPF)
      #   sbi    — HTTP-2/TCP port 7777   (SBI: inter-NF API)
      #   custom — arbitrary iptables rules via RULE_IN / RULE_OUT
      #   (empty/unset) — same as custom; requires RULE_IN / RULE_OUT
      - IDS_MODE=n2
      - IDS_QUEUE=0
      - IDS_CONF_FILE=/home/snorty/custom/custom_snort.lua
      - IDS_VERBOSE=1
      - IDS_DAQ_MODE=nfq
      - IDS_ALERT_MODE=alert_json
      # Per-interface overrides (defaults shown):
      - N2_IF=lo
      - N2_PORT=38412
      - N3_IF=ens3
      - N3_PORT=2152
      - TUN_IF=ogstun
      - N4_IF=lo
      - N4_PORT=8805
      - SBI_IF=lo
      - SBI_PORT=7777
    privileged: true
    stdin_open: true
    tty: true
    restart: unless-stopped

volumes:
  alerts_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/alerts

  custom_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/custom
```

### Variables

#### Core IDS variables

| Variable         | Default                                  | Description                                                                 |
| ---------------- | ---------------------------------------- | --------------------------------------------------------------------------- |
| `IDS_MODE`       | *(empty — same as custom)*               | Which 5G interface/ruleset to activate. See modes table below.              |
| `IDS_QUEUE`      | `0`                                      | NFQUEUE number passed to iptables and the NFQ DAQ.                         |
| `IDS_RULES_FILE` | `/home/snorty/custom/${IDS_MODE}.rules`  | Explicit rules file path. Overrides `IDS_MODE`-based resolution.           |
| `IDS_CONF_FILE`  | `/home/snorty/custom/custom_snort.lua`   | Snort configuration file.                                                   |
| `IDS_VERBOSE`    | `0`                                      | Set to `1` to enable verbose Snort output.                                  |
| `IDS_DAQ_MODE`   | `nfq`                                    | DAQ mode: `nfq` (inline), `afpacket` (inline), or anything else (passive). |
| `IDS_ALERT_MODE` | `alert_json`                             | Snort alert output format (any Snort `-A` value).                          |
| `IDS_DAQ_DEBUG`  | `0`                                      | Set to `1` to enable DAQ debug output.                                      |

#### IDS_MODE values

| Mode     | Protocol  | Port  | Chain                      | Description                        |
| -------- | --------- | ----- | -------------------------- | ---------------------------------- |
| `n2`     | SCTP      | 38412 | INPUT/OUTPUT or FORWARD    | NGAP: AMF ↔ gNB                   |
| `n3`     | UDP       | 2152  | INPUT/OUTPUT + FORWARD     | GTP-U: gNB ↔ UPF + ogstun tunnel  |
| `n4`     | UDP       | 8805  | INPUT/OUTPUT or FORWARD    | PFCP: SMF ↔ UPF                   |
| `sbi`    | TCP       | 7777  | INPUT/OUTPUT or FORWARD    | HTTP/2: Open5GS inter-NF SBI       |
| `custom` | —         | —     | `CHAIN_IN` / `CHAIN_OUT`   | Arbitrary rules via `RULE_IN` / `RULE_OUT` |

> For loopback interfaces (`lo`) the entrypoint uses INPUT/OUTPUT chains; for all other interfaces it uses FORWARD.

#### Per-interface overrides

| Variable    | Default   | Description                              |
| ----------- | --------- | ---------------------------------------- |
| `N2_IF`     | `lo`      | Interface for N2 (NGAP/SCTP) traffic     |
| `N2_PORT`   | `38412`   | Port for N2 traffic                      |
| `N3_IF`     | `ens3`    | Interface for N3 (GTP-U) traffic         |
| `N3_PORT`   | `2152`    | Port for N3 traffic                      |
| `TUN_IF`    | `ogstun`  | Tunnel interface for N3 inner packets    |
| `N4_IF`     | `lo`      | Interface for N4 (PFCP) traffic          |
| `N4_PORT`   | `8805`    | Port for N4 traffic                      |
| `SBI_IF`    | `lo`      | Interface for SBI (HTTP/2) traffic       |
| `SBI_PORT`  | `7777`    | Port for SBI traffic                     |

#### Custom mode

Set `IDS_MODE=custom` (or leave it empty) and provide your own iptables rule arguments:

| Variable    | Default   | Description                                          |
| ----------- | --------- | ---------------------------------------------------- |
| `RULE_IN`   | *(unset)* | Full iptables args for inbound rule, e.g. `-i ens3 -p tcp --dport 9999 -j NFQUEUE --queue-num 0 --queue-bypass` |
| `RULE_OUT`  | *(unset)* | Full iptables args for outbound rule (optional)      |
| `CHAIN_IN`  | `INPUT`   | iptables chain for `RULE_IN`                         |
| `CHAIN_OUT` | `OUTPUT`  | iptables chain for `RULE_OUT`                        |

#### Legacy variables (still supported)

The old variable names are accepted as fallbacks for backward compatibility:

| Old variable       | Maps to          |
| ------------------ | ---------------- |
| `RULES_FILE`       | `IDS_RULES_FILE` |
| `SNORT_CONF_FILE`  | `IDS_CONF_FILE`  |
| `VERBOSE`          | `IDS_VERBOSE`    |
| `SNORT_DAQ_MODE`   | `IDS_DAQ_MODE`   |
| `SNORT_ALERT_MODE` | `IDS_ALERT_MODE` |
| `QUEUE`            | `IDS_QUEUE`      |

#### Other variables

| Variable       | Default                 | Description                                  |
| -------------- | ----------------------- | -------------------------------------------- |
| `SNORT_ALERTS` | `/home/snorty/alerts`   | Directory where Snort writes alert output    |
| `SNORT_BIN`    | `/home/snorty/snort3`   | Path to the Snort installation               |
| `TZ`           | `Europe/Athens`         | Timezone for accurate timestamps             |

### Capabilities

The entrypoint ([`entrypoint.sh`](src/volumes/scripts/entrypoint.sh)) reads `IDS_MODE` and automatically inserts the correct NFQUEUE iptables rules for the selected 5G interface on startup, then removes them cleanly on container stop or SIGTERM.

Snort is launched by [`run_snort.sh`](src/volumes/scripts/run_snort.sh), which constructs the Snort command from the `IDS_*` environment variables.

[`run_snort_notify.sh`](src/volumes/scripts/run_snort_notify.sh) wraps `run_snort.sh` with `inotifywait` to watch the active rules file. When the file is modified, Snort is stopped and restarted automatically — no container restart needed to reload rules. If no watchable rules file can be resolved (e.g. `IDS_MODE=custom` without `IDS_RULES_FILE`), hot-reload is disabled and Snort runs directly.

**DAQ modes:**
- `nfq` — inline mode via NFQUEUE; can alert, drop, and block traffic based on rules.
- `afpacket` — inline mode via AF_PACKET; requires `INTERFACE` to be set.
- *(anything else)* — passive/pcap mode; Snort listens on `INTERFACE` without modifying traffic.

> Note: there is no `stream_sctp` inspector in Snort 3. SCTP (N2/NGAP) packets are processed per-packet without stream reassembly. Do not use the `flow:` keyword in SCTP rules.

## Building the image

To build the Docker image, use the Dockerfile inside the `src` directory and the Makefile.

There are two Dockerfiles:
- `Dockerfile` — builds Snort 3 from source (slow; use for version upgrades).
- `Dockerfile-modified` — layers updated scripts on top of the base image (fast; use for script changes).

```bash
make build           # build base image from source
make build-modified  # rebuild with updated scripts only
make push            # tag and push to Docker Hub
```

More information about the Makefile can be found in [docs/makefile.md](docs/makefile.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
