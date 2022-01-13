# Introduction

This lightweight set of Kubernetes manifest YAML is suitable for running a cluster on a Kubernetes cluster of your choice. (AWS EKS has
been included as a starting point but you can readily use [Minikube](https://minikube.sigs.k8s.io/docs/start/) or [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/) to experiment apart from the public cloud.) 

This sub-package is structured similarly to the [outer package](../README.md) as a Makefile with multiple targets. As with running a local
cluster via docker-compose, choose the steps (targets) that you require. A typical flow will goes as:
* Start up your Kubernetes cluster. For EKS, see [#start-an-eks-cluster] & [#stop-an-eks-cluster]
* Prepare the cluster with a namespace and AWS credential secret [#prepare-the-kubernetes-cluster]
* Start up your desired Presto [#start-up-prestox]
* Validate the readiness of your cluster [#validate-your-cluster]
* Set up port-forwarding to access the coordinator Web UI [#access-server-web-ui]
* Use your server [#use-your-server]
* Scale the cluster as required [#scale-your-prestox-cluster]
* Stop Presto [#stop-prestox]
* Tear down your Kubernetes cluster. For EKS, see [#stop-an-eks-cluster]



## Pre-requisite

The material in this directory requires the Kubernetes CLI:
1. kubectl

You will also need a set of container images as defined in the [outer package](../README.md)

Additional dependency vary according to the Kubernetes platform you choose. If you are using AWS/EKS, this would be:

1. `AWS CLI`
2. [`eksctl`](https://eksctl.io/)

All are readily available from Homebrew:
```sh
$ brew install kubectl
# choose your Kubernetes platform
$ brew install awscli eksctl
```


## AWS EKS


### Starting an EKS cluster 

Start by creating a cluster. This is a relatively slow process (~20 minutes) so start it before your coffee/tea/drink. Check the `Makefile` for the specification of the nodes. By default, we use 2 nodes (NODES) of [`m4.xlarge`](https://aws.amazon.com/ec2/instance-types/)(NTYPE) (4 vCPU; 16 GiB with 'High' Network Performance).


```sh
# Start an EKS cluster
$ make eksup
eksctl create cluster \
		--region us-west-2 --version 1.21 --name trino-eks-benchmark \
		--nodegroup-name worker-nodes --node-type m4.2xlarge --nodes 2 --nodes-min 2 --nodes-max 5 --managed 
2022-01-04 11:19:18 [ℹ]  eksctl version 0.76.0
2022-01-04 11:19:18 [ℹ]  using region us-west-2
2022-01-04 11:19:18 [ℹ]  setting availability zones to [us-west-2a us-west-2d us-west-2c]
2022-01-04 11:19:18 [ℹ]  subnets for us-west-2a - public:192.168.0.0/19 private:192.168.96.0/19
2022-01-04 11:19:18 [ℹ]  subnets for us-west-2d - public:192.168.32.0/19 private:192.168.128.0/19
2022-01-04 11:19:18 [ℹ]  subnets for us-west-2c - public:192.168.64.0/19 private:192.168.160.0/19
2022-01-04 11:19:18 [ℹ]  nodegroup "worker-nodes" will use "" [AmazonLinux2/1.21]
2022-01-04 11:19:18 [ℹ]  using Kubernetes version 1.21
2022-01-04 11:19:18 [ℹ]  creating EKS cluster "trino-eks-benchmark" in "us-west-2" region with managed nodes
2022-01-04 11:19:18 [ℹ]  will create 2 separate CloudFormation stacks for cluster itself and the initial managed nodegroup
2022-01-04 11:19:18 [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-west-2 --cluster=trino-eks-benchmark'
2022-01-04 11:19:18 [ℹ]  CloudWatch logging will not be enabled for cluster "trino-eks-benchmark" in "us-west-2"
2022-01-04 11:19:18 [ℹ]  you can enable it with 'eksctl utils update-cluster-logging --enable-types={SPECIFY-YOUR-LOG-TYPES-HERE (e.g. all)} --region=us-west-2 --cluster=trino-eks-benchmark'
2022-01-04 11:19:18 [ℹ]  Kubernetes API endpoint access will use default of {publicAccess=true, privateAccess=false} for cluster "trino-eks-benchmark" in "us-west-2"
2022-01-04 11:19:18 [ℹ]  
2 sequential tasks: { create cluster control plane "trino-eks-benchmark", 
    2 sequential sub-tasks: { 
        wait for control plane to become ready,
        create managed nodegroup "worker-nodes",
    } 
}
2022-01-04 11:19:18 [ℹ]  building cluster stack "eksctl-trino-eks-benchmark-cluster"
2022-01-04 11:19:19 [ℹ]  deploying stack "eksctl-trino-eks-benchmark-cluster"
2022-01-04 11:19:49 [ℹ]  waiting for CloudFormation stack "eksctl-trino-eks-benchmark-cluster"
...
2022-01-04 11:34:23 [ℹ]  waiting for CloudFormation stack "eksctl-trino-eks-benchmark-cluster"
2022-01-04 11:36:25 [ℹ]  building managed nodegroup stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes"
2022-01-04 11:36:25 [ℹ]  deploying stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes"
2022-01-04 11:36:25 [ℹ]  waiting for CloudFormation stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes"
...
2022-01-04 11:40:00 [ℹ]  waiting for CloudFormation stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes"
2022-01-04 11:40:00 [ℹ]  waiting for the control plane availability...
2022-01-04 11:40:00 [✔]  saved kubeconfig as "/Users/gkyc/.kube/config"
2022-01-04 11:40:00 [ℹ]  no tasks
2022-01-04 11:40:00 [✔]  all EKS cluster resources for "trino-eks-benchmark" have been created
2022-01-04 11:40:00 [ℹ]  nodegroup "worker-nodes" has 2 node(s)
2022-01-04 11:40:00 [ℹ]  node "ip-192-168-27-245.us-west-2.compute.internal" is ready
2022-01-04 11:40:00 [ℹ]  node "ip-192-168-85-244.us-west-2.compute.internal" is ready
2022-01-04 11:40:00 [ℹ]  waiting for at least 2 node(s) to become ready in "worker-nodes"
2022-01-04 11:40:00 [ℹ]  nodegroup "worker-nodes" has 2 node(s)
2022-01-04 11:40:00 [ℹ]  node "ip-192-168-27-245.us-west-2.compute.internal" is ready
2022-01-04 11:40:00 [ℹ]  node "ip-192-168-85-244.us-west-2.compute.internal" is ready
2022-01-04 11:40:01 [ℹ]  kubectl command should work with "/Users/gkyc/.kube/config", try 'kubectl get nodes'
2022-01-04 11:40:01 [✔]  EKS cluster "trino-eks-benchmark" in "us-west-2" region is ready
kubectl config rename-context `kubectl config current-context` trino 
Context "george.chow@trino-eks-benchmark.us-west-2.eksctl.io" renamed to "trino".
```

The last step of the startup renamed the EKS' verbose context name (`george.chow@trino-eks-benchmark.us-west-2.eksctl.io`) into a shorter name (`trino`). This short name is specified via $(K8S_CTX) and is similarly neither interpreted nor significant. Adjust as you see fit.



### Stop an EKS cluster 

To stop the EKS cluster:
```sh
# Stop your EKS cluster
$ make eksdown
eksctl delete cluster --name trino-eks-benchmark --region us-west-2
2022-01-04 19:16:38 [ℹ]  eksctl version 0.76.0
2022-01-04 19:16:38 [ℹ]  using region us-west-2
2022-01-04 19:16:38 [ℹ]  deleting EKS cluster "trino-eks-benchmark"
2022-01-04 19:16:38 [ℹ]  will drain 0 unmanaged nodegroup(s) in cluster "trino-eks-benchmark"
2022-01-04 19:16:39 [ℹ]  deleted 0 Fargate profile(s)
2022-01-04 19:16:39 [✔]  kubeconfig has been updated
2022-01-04 19:16:39 [ℹ]  cleaning up AWS load balancers created by Kubernetes objects of Kind Service or Ingress
2022-01-04 19:16:40 [ℹ]  
2 sequential tasks: { delete nodegroup "worker-nodes", delete cluster control plane "trino-eks-benchmark" [async] 
}
2022-01-04 19:16:41 [ℹ]  will delete stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes"
2022-01-04 19:16:41 [ℹ]  waiting for stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes" to get deleted
2022-01-04 19:16:41 [ℹ]  waiting for CloudFormation stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes"
2022-01-04 19:16:41 [!]  retryable error (Throttling: Rate exceeded
	status code: 400, request id: 6ee2addd-51f3-4f48-9d59-b0a9ecda042a) from cloudformation/DescribeStacks - will retry after delay of 7.888854423s
2022-01-04 19:17:05 [ℹ]  waiting for CloudFormation stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes"
...
2022-01-04 19:20:38 [ℹ]  waiting for CloudFormation stack "eksctl-trino-eks-benchmark-nodegroup-worker-nodes"
2022-01-04 19:20:39 [ℹ]  will delete stack "eksctl-trino-eks-benchmark-cluster"
2022-01-04 19:20:39 [✔]  all cluster resources were deleted
```

You can examine your cluster (checking on its state and resources) with:
```sh
# Describe the cluster
$ make eksdescribe
aws eks describe-cluster --name trino-eks-benchmark --output json
{
    "cluster": {
        "name": "trino-eks-benchmark",
        "arn": "arn:aws:eks:us-west-2:534790972160:cluster/trino-eks-benchmark",
        "createdAt": "2022-01-04T11:20:02.346000-08:00",
        "version": "1.21",
        "endpoint": "https://4EEEEE3F24454CD083D8D6E96F17A82B.gr7.us-west-2.eks.amazonaws.com",
        "roleArn": "arn:aws:iam::534790972160:role/eksctl-trino-eks-benchmark-cluster-ServiceRole-18H4GBVTR2F2Q",
        "resourcesVpcConfig": {
            "subnetIds": [
                "subnet-0e48c07e8c3172c0b",
                "subnet-019c2a779f80e56cc",
                "subnet-0e0423ab7b3765823",
                "subnet-0e40e6b2a2d38e2eb",
                "subnet-0151e0b83f1d72eb0",
                "subnet-0bf31be616bfb10fa"
            ],
            "securityGroupIds": [
                "sg-03ff1763cba4d23f5"
            ],
...
        "platformVersion": "eks.4",
        "tags": {
            "aws:cloudformation:stack-name": "eksctl-trino-eks-benchmark-cluster",
            "aws:cloudformation:logical-id": "ControlPlane",
            "alpha.eksctl.io/cluster-name": "trino-eks-benchmark",
            "aws:cloudformation:stack-id": "arn:aws:cloudformation:us-west-2:534790972160:stack/eksctl-trino-eks-benchmark-cluster/36f10cf0-6d93-11ec-b369-02562d0c6ec1",
            "alpha.eksctl.io/eksctl-version": "0.76.0",
            "eksctl.cluster.k8s.io/v1alpha1/cluster-name": "trino-eks-benchmark"
        }
    }
}
```


## Prepare the Kubernetes cluster


Before starting up your cluster, confirm and/or prepare the context. If you used the built-in EKS targets, this would be handled already. If you are using some other platform for your Kubernetes cluster, do likewise.

```sh
% make status
kubectl config get-contexts
CURRENT   NAME       CLUSTER                                   AUTHINFO                                              NAMESPACE
          minikube   minikube                                  minikube                                              trino
*         trino      trino-eks-benchmark.us-west-2.eksctl.io   george.chow@trino-eks-benchmark.us-west-2.eksctl.io   
```

The `*` indicates the context named `trino` is current selected. The context is defined for the indicated cluster and user. You may have any number of contexts but only one is 'selected' at a time.

If you do not have a `*` shown, you can designate a specific context as your current via:
```sh
$ kubectl config use-context foo
Switched to context "foo".
```


Creat a namespace in your cluster to organize your resources and set it as your default (to save typing). The choice of the name here (`trino`) is 
a reminder for you and not significant; adjust accordingly via the Makefile variable $(NS).
```sh
$ make ns
kubectl create ns trino
namespace/trino created
$ make default
kubectl config set-context --current --namespace=trino
Context "trino" modified.
```

To use the demo image's `deltas3` catalog, set up your AWS keys via a Kubernetes secret:

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

## Start up PrestoX

(This section indicates PrestoX to emphasize the generality of this package across both forks of Presto.)

To start up your desired Presto fork:

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

The 

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

Wait until all worker pods are in a running state before proceeding onward to validate your cluster.


# Validate your Cluster

To check on the cluster's startup, use the `nodecheck` target. It uses the query 

```SQL
SELECT * FROM system.runtime.nodes;
```

to fetch all operational nodes of the cluster.

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

For a large cluster, it may take multiple minutes for all workers to announce themselves to the coordinator. Workers are ephemeral and may crash
and/or be terminated by Kuberenetes. However, Kubernetese will bring up replacements as worker die to fulfill the declared replica count, subject to available resource in your Kubernetes cluster. 

# Use your Server

To interact with your server interactively, run the CLI by launching the packed-in binary inside the coordinator node:

```sh
$ make cli
kubectl exec coordinator-0 -it -- trino-cli
trino> 
```

## Scale your PrestoX cluster

To scale your cluster's workers (within the bounds of the Kubernetes cluster), use `kubectl` directly on the `worker` `statefulset`. The exmaple below
scales up your cluster to 10 nodes

```sh
$ kubectl scale --replicas=10 statefulset/worker
statefulset.apps/worker scaled
```
The desired number of workers is the replica value. Do provide sufficient time for the workers to start up and to register themselves with the cluster coordinator. Workers are created serially in a Kubernetes statefulset so be patient if you are scaling up to a large number of workers. See [#validate-your-cluster] to monitor the progress.


## Access server Web UI

To use the PrestoX's Web UI, start up a terminal to run a port-forward tunnel. While the port-foward is active, you can monitor PrestoX via [http://localhost:8080](http://localhost:8080). If the coordinator's pod dies, this tunnel will need to be re-established.

```sh
$ make portforward
kubectl port-forward coordinator-0 8080:8080
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
E0104 19:17:06.252134   19387 portforward.go:406] an error occurred forwarding 8080 -> 8080: error forwarding port 8080 to pod aada1f2919c9039242e6528150f3ac3668f4e20ff5431850b343c18d190ccd82, uid : container not running (aada1f2919c9039242e6528150f3ac3668f4e20ff5431850b343c18d190ccd82)
E0104 19:17:06.254085   19387 portforward.go:406] an error occurred forwarding 8080 -> 8080: error forwarding port 8080 to pod aada1f2919c9039242e6528150f3ac3668f4e20ff5431850b343c18d190ccd82, uid : container not running (aada1f2919c9039242e6528150f3ac3668f4e20ff5431850b343c18d190ccd82)
E0104 19:17:06.252138   19387 portforward.go:406] an error occurred forwarding 8080 -> 8080: error forwarding port 8080 to pod aada1f2919c9039242e6528150f3ac3668f4e20ff5431850b343c18d190ccd82, uid : container not running (aada1f2919c9039242e6528150f3ac3668f4e20ff5431850b343c18d190ccd82)
E0104 19:17:06.254786   19387 portforward.go:234] lost connection to pod
Handling connection for 8080
E0104 19:17:06.256187   19387 portforward.go:346] error creating error stream for port 8080 -> 8080: EOF
```

## Stop PrestoX


To stop your PrestoX cluster:
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


## Related material

The adjacent repo [overcoil/c2-presto-delta-test-material](https://github.com/overcoil/c2-presto-delta-test-material) contains ready-to-use queries that you can set up inside this package:

```sh
$ cd ~
$ git clone https://github.com/overcoil/c2-presto-delta-test-material
# material is now at ~/c2-presto-delta-test-material

$ cd prestoX-cluster/k8s
$ ln -s ../../c2-presto-delta-test-material/node-check.sql .
$ ln -s ../../c2-presto-delta-test-material/tpcds-sanity.sql .
# use indirection to skip the typing
$ make cli < tpcds-sanity.sql
```



## TPC-DS

TODO

```sh
$ ln -s ../../c2-presto-delta-test-material/tpcdsq96.sql .
$ make q96
kubectl exec coordinator-0 -it -- trino-cli < tpcdsq96.sql
Unable to use a TTY - input is not a terminal or the right kind of file
Jan 04, 2022 11:00:00 PM org.jline.utils.Log logr
WARNING: Unable to create a system terminal, creating a dumb terminal (enable debug logging for more information)
"707342"
```


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

## Resources

[k9s](https://k9scli.io/) is more convenient than `kubectl` especially for watching the logs and dropping into your nodes.
