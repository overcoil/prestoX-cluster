# Introduction

This minimal set of Kubernetes manifest is used to bring up a flexible cluster in AWS EKS. The majority of the targets in
the Makefile are for Kubernetes and useable with a cluster on any cloud (Azure AKS, GCP GKE, etc).



## Pre-requisite

The material in this directory requires the Kubernetes CLI:
1. kubectl

As well, the assumption is that you have a Trino binary and/or set of container images as defined in the directory above. 

Additional dependency vary according to the Kubernetes platform you choose. If you are using AWS/EKS, this would be:

1. `AWS CLI`
2. [`eksctl`](https://eksctl.io/)

All are readily avaiable from Homebrew:
```sh
$ brew install kubectl
# choose your Kubernetes platform
$ brew install awscli eksctl
```


## AWS EKS


Start by creating a cluster. This is a relatively slow process (~20 minutes) so start it before your coffee/tea/drink. Check the `Makefile` for the specification of the nodes. By default, we use 2 nodes (NODES) of [`m4.xlarge`](https://aws.amazon.com/ec2/instance-types/)(NTYPE) (4 vCPU; 16 GiB with 'High' Network Performance).


```sh
# Start up your EKS cluster
$ make eksup
```

You stop the cluster with:
```sh
# Stop your EKS cluster
$ make eksdown
```

You can examine your cluster with:
```sh
# Describe the cluster
$ make eksdescribe
```


## Kubernetes

To work with Kubernetes, verify your cluster is ready:
```sh
% make status
kubectl config get-contexts
CURRENT   NAME       CLUSTER    AUTHINFO   NAMESPACE
*         minikube   minikube   minikube   trino
```

The `*` indicates the context named `minikube` is current selected. The context happens to be defined for a cluster named `minikube`. You may have any number of contexts but only one is 'selected' at a time.

If you do not have a `*` shown, you can designate a specific context as your current via:
```sh
$ kubectl config use-context foo
Switched to context "foo".
```

Start by creating a namespace in the cluster to organize your resources and setting it as your default (to save typing):
```sh
$ make ns
kubectl create ns trino
namespace/trino created
$ make default
kubectl config set-context --current --namespace=trino
Context "minikube" modified.
```

Before you can start up Trino, set up your AWS keys via a Kubernetes secret:
```sh
# create secret-awscred.yaml from secret-awscred.yaml-tpl and fill in appropriately
$ cp secret-awscred.yaml-tpl secret-awscred.yaml
# edit secret-awscred.yaml as required
$ make awscred
kubectl -n trino apply -f secret-awscred.yaml
secret/secret-awscred configured
```

Confirm that the secret is available:

```sh
$ make ls
eksctl get cluster --region us-west-2 -v 0
No clusters found
kubectl -n trino get secret,svc,deploy,statefulset,po
NAME                         TYPE                                  DATA   AGE
secret/default-token-7vkjr   kubernetes.io/service-account-token   3      5d4h
secret/secret-awscred        Opaque                                2      5d4h
```


To start up Trino:
```sh
$ make start
kubectl -n trino apply -f coordinator.yaml -f workers.yaml
service/coordinator created
serviceaccount/svc-coordinator created
statefulset.apps/coordinator created
service/worker created
serviceaccount/svc-worker created
statefulset.apps/worker created
```

Now confirm the system is starting up:

```sh
$ make ls
eksctl get cluster --region us-west-2 -v 0
No clusters found
kubectl -n trino get secret,svc,deploy,statefulset,po
NAME                                 TYPE                                  DATA   AGE
secret/default-token-7vkjr           kubernetes.io/service-account-token   3      5d4h
secret/secret-awscred                Opaque                                2      5d4h
secret/svc-coordinator-token-xvd9x   kubernetes.io/service-account-token   3      24s
secret/svc-worker-token-qq79s        kubernetes.io/service-account-token   3      23s

NAME                  TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/coordinator   ClusterIP   None         <none>        8080/TCP   25s
service/worker        ClusterIP   None         <none>        8081/TCP   25s

NAME                           READY   AGE
statefulset.apps/coordinator   1/1     25s
statefulset.apps/worker        2/2     24s

NAME                READY   STATUS    RESTARTS   AGE
pod/coordinator-0   1/1     Running   0          24s
pod/worker-0        1/1     Running   0          24s
pod/worker-1        1/1     Running   0          19s
```

To stop Trino:
```sh
$ make stop
kubectl -n trino delete -f coordinator.yaml -f workers.yaml
service "coordinator" deleted
serviceaccount "svc-coordinator" deleted
statefulset.apps "coordinator" deleted
service "worker" deleted
serviceaccount "svc-worker" deleted
statefulset.apps "worker" deleted
```

Wait for the cluster to startup and communication to sync up.

You can use the adjacent repo [https://github.com/overcoil/c2-presto-delta-test-material](https://github.com/overcoil/c2-presto-delta-test-material) which contains precanned queries:

```sh
$ ln -s ../../c2-presto-delta-test-material/node-check.sql .
$ ln -s ../../c2-presto-delta-test-material/tpcds-sanity.sql .
```

Now check on the cluster's startup:
```sh
$ make nodecheck
kubectl exec coordinator-0 -it -- trino-cli < node-check.sql
Unable to use a TTY - input is not a terminal or the right kind of file
Jan 04, 2022 3:08:23 AM org.jline.utils.Log logr
WARNING: Unable to create a system terminal, creating a dumb terminal (enable debug logging for more information)
"worker-0","http://172.17.0.8:8080","359-6-g90ee82e-dirty","false","active"
"worker-1","http://172.17.0.10:8080","359-6-g90ee82e-dirty","false","active"
"coordinator-0","http://172.17.0.4:8080","359-6-g90ee82e-dirty","true","active"
```

You can start up the CLI via the packed-in CLI binary inside the coordinator node:

```sh
$ make cli
kubectl exec coordinator-0 -it -- trino-cli
trino> 
```

To scale the Trino workers (within the bounds of the Kubernetes cluster):
```sh
$ kubectl scale --replicas=1 statefulset/worker
statefulset.apps/worker scaled
```
Specify the desired number of worker via the replica value. Do provide sufficient time for the workers to start up and to register themselves with the cluster coordinator. Workers are created serially in a Kubernetes statefulset so be patient if you are scaling up to a large number of workers. Use the `nodecheck` target above to observe the progress.


## Details

The size of each worker is specified at:
1. [presto-dbx-worker/etc/config.properties (templatized)](https://github.com/overcoil/prestoX-cluster/blob/master/presto-dbx-worker/etc/config.properties.template)
    The default is 3GB.
2. [k8s/workers.yaml](https://github.com/overcoil/prestoX-cluster/blob/master/k8s/workers.yaml)
    Look for StatefulSet's `spec.templates.spec.containers.resources.requests` (the starting point for the container) and `.limits` (the ceiling for the container). The default is 3GB for both.

The coordinator is similarly controlled:
1. [presto-dbx-coordinator/etc/config.properties (templatized)](https://github.com/overcoil/prestoX-cluster/blob/master/presto-dbx-coordinator/etc/config.properties.template)
    The default is 1GB.
2. [k8s/coordinator.yaml](https://github.com/overcoil/prestoX-cluster/blob/master/k8s/coordinator.yaml)
    Look for StatefulSet's `spec.templates.spec.containers.resources.requests` (the starting point for the container) and `.limits` (the ceiling for the container). The default is 2GB and 3GB.

