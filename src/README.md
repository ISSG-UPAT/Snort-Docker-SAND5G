## Details

This version copies into the docker :

- custom (folder): Custom folder contains the snort.lua and the local.rules that snort will run
- scripts (folder): Scripts folder contains the script that will run the command of snort

And binds the directory alerts to the host machine ( /home/snorty/alerts:./volumes/alerts)

## Running

```bash
docker compose up --build -d
```

Accessing shell inside the container

```bash
docker compose exec snorty3 /bin/bash
```

## Stopping

```bash
docker compose down
```
