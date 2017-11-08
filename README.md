# rundeck-alpine

Launches a container with Rundeck (version 2.9.3).

# Build

```sh
docker build -t rundeck-alpine:v1 .
```

# Usage

```sh
$ docker run -d -ti --name my-rundeck \
    --link mysql-container:mysql-host \
    -p 80:4440 -p 443:8443 \
    rundeck-alpine:v1
```