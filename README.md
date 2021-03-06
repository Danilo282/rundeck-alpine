# rundeck-alpine

A containerized version of RunDeck (v2.10.8). It uses a multi-staged build to provide three Docker images:

- **basic**: only contains a default installation of RunDeck (launcher installation). It is useful to use as a parent image for your containers
- **templated**: also includes ConfD to help creating a default setup of RunDeck in the first running
- **production**: contains some files provisioned via ConfD, and Supervisor to control services related to RunDeck runtime.

## Build

To build this container you can simply run the following command:

```sh
docker build -t rundeck:alpine .
```

## Usage

By default, this container only needs variable `DATASOURCE_PASSWORD` to start running. However, it is helpful to mount the defined `RDECK_BASE/logs` on container's host to avoid losing logs data when container is killed, for example.

```sh
$ docker run -d -ti --name my-rundeck \
    --link mysql-container:mysql-host \
    -e DATASOURCE_PASSWORD="DB_PASSWORD_HERE" \
    -p 4440:4440 \
    hugomcfonseca/rundeck:alpine
```
