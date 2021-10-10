# docker-presto-cluster

docker-presto-cluster is a simple tool for launching multiple node [Presto](https://prestosql.io/) cluster on docker container. 

This repo is forked from [Lewuathe/docker-trino-cluster](https://github.com/Lewuathe/docker-trino-cluster) porting it to make it work with latest versions of presto


- [Usage](#usage)
  * [docker-compose.yml](#docker-composeyml)
- [Development](#development)
  * [Build Image](#build-image)
  * [Snapshot Image](#snapshot-image)
- [LICENSE](#license)





# Usage

Images are uploaded in [DockerHub](https://hub.docker.com/).  Each docker image gets two arguments

|Index|Argument|Description|
|:---|:---|:---|
|1|discovery_uri| Required parameter to specify the URI to coordinator host|
|2|node_id|Optional parameter to specify the node identity. UUID will be generated if not given|

You can launch multi node Presto cluster in the local machine as follows.

```sh
# Create a custom network
$ docker network create presto_network

# Launch coordinator
$ docker run -p 8080:8080 -it \
    --net presto_network \
    --name coordinator \
    saj1th/presto-dbx-coordinator:0.263 http://localhost:8080

# Launch two workers
$ docker run -it \
    --net presto_network \
    --name worker1 \
    saj1th/presto-dbx-worker:0.263 http://coordinator:8080

$ docker run -it \
    --net presto_network \
    --name worker2 \
    saj1th/presto-dbx-worker:0.263 http://coordinator:8080
```


## docker-compose.yml

[`docker-compose`](https://docs.docker.com/compose/compose-file/) enables us to coordinator multiple containers more easily. You can launch a multiple node docker presto cluster with the following yaml file. `command` is required to pass discovery URI and node id information which must be unique in a cluster. If node ID is not passed, the UUID is generated automatically at launch time.

```yaml
version: '3'

services:
  coordinator:
    image: "saj1th/presto-dbx-coordinator:${PRESTO_VERSION}"
    ports:
      - "8080:8080"
    container_name: "coordinator"
    command: http://coordinator:8080 coordinator
  worker0:
    image: "saj1th/presto-dbx-worker:${PRESTO_VERSION}"
    container_name: "worker0"
    ports:
      - "8081:8081"
    command: http://coordinator:8080 worker0
  worker1:
    image: "saj1th/presto-dbx-worker:${PRESTO_VERSION}"
    container_name: "worker1"
    ports:
      - "8082:8081"
    command: http://coordinator:8080 worker1
```

The version can be specified as the environment variable.

```
$ PRESTO_VERSION=0.263 docker-compose up
```

# Custom Catalogs

While the image provides several default connectors (i.e. JMX, Memory, TPC-H and TPC-DS), you may want to override the catalog property with your own ones. That can be easily achieved by mounting the catalog directory onto `/usr/local/presto/etc/catalog`. Please look at [`volumes`](https://docs.docker.com/compose/compose-file/#volumes) configuration for docker-compose.

```yaml
services:
  coordinator:
    image: "saj1th/presto-dbx-coordinator:${PRESTO_VERSION}"
    ports:
      - "8080:8080"
    container_name: "coordinator"
    command: http://coordinator:8080 coordinator
    volumes:
      - ./example/etc/catalog:/usr/local/presto/etc/catalog
```

# Development

## Build Image

```
$ make build
```

## Snapshot Image

You may want to run presto with custom build 

```
$ make snapshot
```

# LICENSE

[Apache v2 License](https://github.com/saj1th/docker-presto-cluster/blob/master/LICENSE)
