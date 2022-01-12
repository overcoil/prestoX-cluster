# prestoX-cluster

prestoX-cluster is a package for for running a Presto cluster either for local test (using docker-compose) or large scale realistic benchmarking (using Kubernetes). This package is useable for both forks of "Presto": either the original [PrestoDB](https://prestodb.io/) or the newer [PrestoSQL/Trino fork](https://trino.io/)).

For disambiguation, I will write "Presto" to refer to either fork; I will use "PrestoDB" or "Trino" directly when I am referring to a particular fork.

This package is derived from [Lewuathe/docker-trino-cluster](https://github.com/Lewuathe/docker-trino-cluster) and [saj1th/docker-presto-cluster](https://github.com/saj1th/docker-presto-cluster).

- [Usage](#usage)
  * [docker-compose.yml](#docker-composeyml)
- [Development](#development)
  * [Build Image](#build-image)
  * [Snapshot Image](#snapshot-image)
- [LICENSE](#license)

# Prerequisite

The starting point for using this package are the build artifacts (e.g., `presto-server-*.tar.gz`/`presto-cli-*-executable.jar` or `trino-server-*.tar.gz`/`trino-cli-*-executable.jar` ) as output by either Presto builds ([PrestoDB](https://prestodb.io/docs/current/installation/deployment.html), [Trino](https://trino.io/docs/current/installation/deployment.html)). This package is also useable with custom builds of either (say, from a private/local fork). Irrespective, keep tab of the fork you're working on as that drives the names for downstream outputs (e.g., Docker containers, Kubernetes manifests, etc). In the case of Trino, this package is useable for version 351 and onward which uses the new name (Trino). (See [Release 351](https://trino.io/docs/current/release/release-351.html) for details on specifics.)

# Usage

Use the [Makefile](https://github.com/overcoil/prestoX-cluster/blob/master/Makefile) to execute each step as required. 


(I have a set of images based on [Presto 0.266]() and [a Trino 359-based fork]() available for demo/exploration at:
* [https://hub.docker.com/repository/docker/overcoil/presto-base](https://hub.docker.com/repository/docker/overcoil/presto-base)
* [https://hub.docker.com/repository/docker/overcoil/presto-dbx-coordinator](https://hub.docker.com/repository/docker/overcoil/presto-dbx-coordinator)
* [https://hub.docker.com/repository/docker/overcoil/presto-dbx-worker](https://hub.docker.com/repository/docker/overcoil/presto-dbx-worker) )

* [https://hub.docker.com/repository/docker/overcoil/trino-base](https://hub.docker.com/repository/docker/overcoil/trino-base)
* [https://hub.docker.com/repository/docker/overcoil/trino-dbx-coordinator](https://hub.docker.com/repository/docker/overcoil/trino-dbx-coordinator)
* [https://hub.docker.com/repository/docker/overcoil/trino-dbx-worker](https://hub.docker.com/repository/docker/overcoil/trino-dbx-worker) )

## Specify the Version

```sh
$ vi Makefile
# specify the version you are working with
# fill in TRINO_VER & PRESTO_VER as required
```

## Source the build artifacts
The Makefile assumes that you have the Presto artifacts installed/available in your local Maven repo. If you are doing otherwise, skip the following and instead place the two binaries into `presto-base` directly. We require both the server run-time package and the executable CLI. Remember to also set the permissions.

|Presto Variant|Server run-time|CLI|
|:---|:---|:---|
|PrestoDB|`presto-server-<version>.tar.gz`| `presto-cli-<version>-executable.jar`|
|Trino|`trino-server-<version>.tar.gz`| `trino-cli-<version>-executable.jar`|


```sh
# to extract the PrestoDB .tar.gz from your Maven repo
$ make pcopy
```

```sh
# to extract the Trino .tar.gz from your Maven repo
$ make tcopy
```

## Build the Docker images

To build the Docker images, decide on the container registry and user id you will use and set the value of `DOCKERHUB_ID` appropriately. This value must be supplied even if you plan to run a local cluster. (In that case, you can skip the push to the container registry.) If you are using Kubernetes, you *must* push your images to a container registry for your Kubernetes cluster to find your images. The example below is for my id (`overcoil`) in DockerHub  (`docker.io`).


```sh
# to build PrestoDB images
$ DOCKERHUB_ID=docker.io/overcoil make pdev
```

```sh
# to build Trino images
$ DOCKERHUB_ID=docker.io/overcoil make tdev
```

The CLI executable is installed into the coordinator node's image for your convenience. You will be able to `docker exec` into the node to use it. See [] below.


## Push your Docker images (optional)
If you plan to run your cluster from Kubernetes, you *must* push your images to a container registry for your Kubernetes cluster to pull from. You will also need to push your images if you wish to share them with other. Remember to set the permission of your images and configure the authentication you require in your cluster. 


```sh
# to push your PrestoDB images
$ DOCKERHUB_ID=docker.io/overcoil make ppush
```

```sh
# to push your Trino images
$ DOCKERHUB_ID=docker.io/overcoil make tpush
```

Each invocation of a Docker image (corresponding to one node of your Presto cluster) is invoked with up to six arguments:

|Index|Argument|Description|Default Value|
|:---|:---|:---|:---|
|1|discovery_uri| Required parameter to specify the URI to coordinator host| N/A|
|2|node_id|Optional parameter to specify the node identity.|generated UUID|
|3|querymaxmemorypernode|Parameter to specify the node's `query.max-memory-per-node` setting inside its `config.properties`|`8GB` REVISIT|
|4|querymaxtotalmemorypernode|Parameter to specify the node's `query.max-total-memory-per-node` setting inside its `config.properties`|`8GB`|
|5|querymaxmemory|Parameter to specify the node's `query.max-memory` setting inside its `config.properties`|`8GB`|
|6|querymaxtotalmemory|Parameter to specify the node's `query.max-total-memory` setting inside its `config.properties`|`8GB`|

The 4 `query*memory*` settings are used to specify the size of each node. Refer to the memory management properties documentation in [PrestoDB](https://prestodb.io/docs/current/admin/properties.html#memory-management-properties) & [Trino](https://trino.io/docs/current/admin/properties-memory-management.html) for details on these.



## Running a local cluster via `docker-compose.yml`

[`docker-compose`](https://docs.docker.com/compose/compose-file/) enables us to coordinate multiple containers more easily. The pre-built target `prun` and `trun` uses [docker-compose.yml](https://github.com/overcoil/prestoX-cluster/blob/master/docker-compose.yml) to start up a multi-node cluster.

```sh
# to start up a local PrestoDB cluster
$ PRESTVAR=presto DOCKERHUB_ID=docker.io/overcoil make prun
```

```sh
# to start up a local Trino cluster
$ PRESTVAR=trino DOCKERHUB_ID=docker.io/overcoil make trun
```

Before starting up your cluster, review the following section on catalog configuration. In the case of the demo images above (`docker.io/overcoil/presto-*`,  and `trino-*`), a parameterize `deltas3` catalog is included for convenient access to your S3 bucket.  


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
