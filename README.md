# Snort Docker Image

## Description of the SAND5G Project

5G -and beyond- networks provide a strong foundation for EU’s digital transformation and are becoming one of the Union’s key assets to compete in the global market.

Securing 5G networks and the services running on top of them requires high quality technical security solutions and also strong collaboration at the operational level.

https://sand5g-project.eu

<img src="https://sand5g-project.eu/wp-content/uploads/2024/06/SAND5G-logo-600x137.png" alt="SAND5G" width="300" height="68">

## What it is

This is a Docker image for Snort, a popular open-source network intrusion detection system (NIDS) and Intrusion Prevention System. This image is designed to be easy to use and configure, allowing you to quickly set up Snort in a Docker container.

It is build from sources and releases of the tool snort, and has some added functionalities.

The current image on dockerhub is of [snort v3.9.1.0](https://github.com/snort3/snort3/tree/3.9.1.0)

## How to use

### Docker compose command

```bash
docker compose up
```

### Docker compose file :

```yaml
services:
  snort3:
    image: snort-docker-sand5g-modified:latest
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
      - RULES_FILE=/home/snorty/custom/custom_alert_drop_block.rules
      - INTERFACE=ens3
      - VERBOSE=1
      - SNORT_ALERT_MODE=alert_json
      - SNORT_DAQ_MODE=nfq
      - INTERFACE=ens3
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
      device: ./volumes/alerts

  custom_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./volumes/custom
```

### Variables

| Variable         | Required | Default Value                        | Description                                               |
| ---------------- | -------- | ------------------------------------ | --------------------------------------------------------- |
| RULES_FILE       | OPTIONAL | /home/snorty/custom/local.rules      | Which rule file to use                                    |
| SNORT_CONF_FILE  | OPTIONAL | /home/snorty/custom/custom_snort.lua | Which configuration file to use                           |
| SNORT_ALERTS     | YES      | /home/snorty/alerts                  | Which folder to use for alert output                      |
| TZ               | YES      | Europe/Athens                        | Used to have accurate timestamps                          |
| INTERFACE        | YES      | <>                                   | The interface to monitor.                                 |
|                  |          |                                      | Default is the first interface available in the system    |
| VERBOSE          | OPTIONAL | 0                                    | The verbosity level of the snort output. ( 0 or 1 )       |
| SNORT_ALERT_MODE | OPTIONAL |                                      | The format of Snort alerts (options come from snort tool) |
| SNORT_DAQ_MODE   | OPTIONAL |                                      | The Snort DAQ mode to use (nfq or afpackets)              |

### Capabilities

The container is running the snort command that is being build from the docker-compose environmental variables and the Dockerfile.
You can find the source code in [run_snort.sh](src/volumes/scripts/run_snort.sh).

It uses the `notify` program, to keep track of movements in the `$RULES_FILE`. If the file is modified, it will automatically reload the rules and restart snort. (see [run_snort_notify.sh](src/volumes/scripts/run_snort_notify.sh))

The afpackets DAQ mode has not been tested and is not guaranteed to work.

The nfq DAQ mode has been tested. It puts the snort in inline mode, and can alert, drop and block the traffic based on the rules provided in the `$RULES_FILE`.

Inside the snort.lua conf daq is not set.

## Building the image

To build the Docker image, you can use the Dockerfile inside the `src` directory and the Makefile.

There are two Dockerfiles. Since building from releases takes a lot of time, the Dockerfile-modified is an image you can use when you want to test out small changes to the Dockerfile.

More information about the Makefile can be found in the [Makefile](docs/makefile.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
