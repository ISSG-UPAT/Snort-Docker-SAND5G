# Snort Docker Image

## Description of the SAND5G Project

5G -and beyond- networks provide a strong foundation for EU’s digital transformation and are becoming one of the Union’s key assets to compete in the global market.

Securing 5G networks and the services running on top of them requires high quality technical security solutions and also strong collaboration at the operational level.

https://sand5g-project.eu

<img src="https://sand5g-project.eu/wp-content/uploads/2024/06/SAND5G-logo-600x137.png" alt="SAND5G" width="300" height="68">

## What it is

This is a Docker image for Snort, a popular open-source network intrusion detection system (NIDS). This image is designed to be easy to use and configure, allowing you to quickly set up Snort in a Docker container.

It is based on the official Snort image and includes additional features and configurations to enhance its usability. `ciscotalos/snort:latest`

## How to use

Pull the image from Docker Hub:

### Docker compose file :

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
      - /path/to/custom:/home/snorty/custom
      - alerts_data:/home/snorty/alerts
      - /etc/localtime:/etc/localtime:ro # Bind mount to sync time
    environment:
      - SNORT_ALERTS=/home/snorty/alerts
      # - RULES_FILE=/home/snorty/custom/local.rules
      # - SNORT_CONF_FILE=/home/snorty/custom/custom_snort.lua
      - INTERFACE=<INTERFACE>
      - TZ=Europe/Athens

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
```

### Variables

| Variable        | Required | Default Value                        | Description                                            |
| --------------- | -------- | ------------------------------------ | ------------------------------------------------------ |
| RULES_FILE      | OPTIONAL | /home/snorty/custom/local.rules      | Which rule file to use                                 |
| SNORT_CONF_FILE | OPTIONAL | /home/snorty/custom/custom_snort.lua | Which configuration file to use                        |
| SNORT_ALERTS    | YES      | /home/snorty/alerts                  | Which folder to use for alert output                   |
| TZ              | YES      | Europe/Athens                        | Used to have accurate timestamps                       |
| INTERFACE       | YES      | <>                                   | The interface to monitor.                              |
|                 |          |                                      | Default is the first interface available in the system |

### Capabilities

The containers is running the following snort command :

```bash
snort -q -c $SNORT_CONF_FILE -i $INTERFACE -A alert_json
```

It uses the `notify` program, to keep track of movements in the `$RULES_FILE`. If the file is modified, it will automatically reload the rules and restart snort. (see [run_snort_notify.sh](src/volumes/scripts/run_snort_notify.sh))

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
