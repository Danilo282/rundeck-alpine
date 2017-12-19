# rundeck-alpine

Launches a container with Rundeck (version 2.10.0).

# Build

To build this container you can simply run the following command:

```sh
docker build -t rundeck-alpine: .
```

# Usage

By default, this container only needs variable `DATASOURCE_PASSWORD` to start running. However, it is helpful to mount the defined `RDECK_BASE/logs` on container's host to avoid losing logs data when container is killed, for example.

```sh
$ docker run -d -ti --name my-rundeck \
    --link mysql-container:mysql-host \
    -e DATASOURCE_PASSWORD="DB_PASSWORD_HERE" \
    -p 4440:4440 \
    hugomcfonseca/rundeck-alpine:latest
```