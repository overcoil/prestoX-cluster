#
# Makefile for operating a Presto cluster in Kubernetes
#
# NB: "px" refers to the Presto in the communal sense of either forks: "PrestoDB" or "Trino"
#
# This Makefile uses the convention operating on underscored yaml as the desired settings.
# This makes it convenient to use sym-links to switch between available choices:
#
#   _eks-cluster.yaml/$EKSYAML : spec for your EKS cluster
#      example: eks/eks-cluster-2xm4.4xlarge.yaml
#
#   _config.yaml: configuration for Presto including JVM heap, node/query memory usage
#      example: cm/cm-configproperties-px-50GB.yaml
#
#   _coordinator.yaml: your cluster coordinator (in a statefulset)
#      example: px-manifests/presto-coordinator.yaml or trino-coordinator.yaml
#   _workers.yaml: your cluster workers (in a statefulset)
#      example: px-manifests/presto-workers.yaml or trino-workers.yaml
#

# ----------
# Kubernetes
# ----------
K8S_CTX=px
NS1=trino
NS2=prestodb

# this Makefile relies on the default namespace to be set (externally)
# $(NS) is only used only for istio
NS=$(NS1)

KC=kubectl
IC=istioctl
ISTIO_NS=istio-system

# Minikube and EKS differ in the patch version supported; adjust as required
KVER=1.21.0
# AWS ref: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html


# --------------------------------
# Kubernetes-platform-specific settings
# --------------------------------

# use this to test config values
#DRY_RUN=--dry-run
DRY_RUN=

PROFILE=default
REGION=us-west-2

AWS=aws --profile $(PROFILE) --region $(REGION) $(DRY_RUN)
EC=AWS_PROFILE=$(PROFILE) eksctl --region $(REGION) $(DRY_RUN)
ECF=AWS_PROFILE=$(PROFILE) eksctl $(DRY_RUN)

# name is used in both var1 and var2
CLUSTER_NAME=trino-feature-eval

# AWS/EKS var1: explicit values

# GP: m4.2xlarge:  8 vCPU/32 Gi RAM; USD0.40/h
# GP: m4.4xlarge: 16 vCPU/64 Gi RAM; USD0.80/h
NG_NAME=managed-ng-worker
NG_LARGE=--node-type m4.4xlarge --nodes 11 --nodes-min 2 --nodes-max 11 --managed 
NG_SMALL=--node-type m4.4xlarge --nodes 2 --nodes-min 2 --nodes-max 5 --managed 
NG_SPEC=$(NG_LARGE)

TAG_SPEC=


# AWS/EKS var2: values inlined into YAML
EKSYAML=_eks-cluster.yaml

# ----------------------------
.phony=mk ns1 ns2 def1 def2 go1 go2 \
	awscred configproperties eksup eksdown dryrun eksdescribe kscale vpcs subnets \
	start stop pf bounce \
	cli nodetest sanity clean rawshell resumeshell \
	istio label unlabel gw vs extern \
	bashc bashw0 bashw1 \
	shrink scale3 scale10 scale20 q96
# =====================================================

# AWS EKS for primary; the rename-context relies on eksctl setting the newly created context/cluster to the current 
# var 1: 
#eksup:
#	$(EC) --region $(REGION) $(DRY_RUN) create cluster \
#		--version $(KVER) --name $(CLUSTER_NAME) \
#       --nodegroup-name $(NG_NAME) $(NG_SPEC) \
#		$(TAG_SPEC)

eksup: $(EKSYAML)
# var 2: use a yaml to specify all parameters; take care to
#        stay in sync with $(CLUSTER_NAME) here!!
	ls -l $(EKSYAML)
	$(ECF) create cluster -f $(EKSYAML)
	# do a version check cuz the -f option above has option to specify KVER
	$(AWS) eks describe-cluster --name $(CLUSTER_NAME) --output json | jq -r '.cluster.version'

    # Use back-ticks for subshell because $(...) notation is used by make
	$(KC) config rename-context `$(KC) config current-context` $(K8S_CTX) 

# use update-kubeconfig if your ~/.kube/config is in the wrong state
ekssync:
	$(AWS) eks update-kubeconfig --name $(CLUSTER_NAME) --alias $(K8S_CTX)

# you can also delete just the nodegroup
eksdown:
	$(EC) delete cluster --name $(CLUSTER_NAME)

# re-install these
up:
	$(EC) create nodegroup --cluster $(CLUSTER_NAME) \
		--name $(NG_NAME) $(NG_SPEC)

# re-install these
down:
	$(EC) delete nodegroup --cluster $(CLUSTER_NAME) --name $(NG_NAME) 

# managed-ng2/managed-ngw hosts Presto workers (note the w suffix)
kscale:
	$(EC) scale nodegroup --cluster $(CLUSTER_NAME) --nodes 10 managed-ngw

kshrink:
	$(EC) scale nodegroup --cluster $(CLUSTER_NAME) --nodes 1 managed-ngw

# =====================================================

ns1:
	$(KC) create ns $(NS1)

ns2:
	$(KC) create ns $(NS2)

# 1 is for Trino so show the versioni too
def1:
	$(KC) config set-context --current --namespace=$(NS1)
	ls -l _coordinator.yaml _workers.yaml
	ls -l trino-coordinator.yaml trino-workers.yaml

def2:
	$(KC) config set-context --current --namespace=$(NS2)
	ls -l _coordinator.yaml _workers.yaml

got:
	rm -f _coordinator.yaml _workers.yaml _config.yaml
	ln -s trino-coordinator.yaml _coordinator.yaml
	ln -s trino-workers.yaml _workers.yaml
	ln -s cm/cm-configproperties-trino-50GB.yaml _config.yaml
	ls -l trino-[cw]*.yaml _config.yaml

gop:
	rm -f _coordinator.yaml _workers.yaml _config.yaml
	ln -s prestodb-coordinator.yaml _coordinator.yaml
	ln -s prestodb-workers.yaml _workers.yaml
	ln -s cm/cm-configproperties-presto-50GB.yaml _config.yaml
	ls -l prestodb-[cw]*.yaml _config.yaml

config: _nodeconfig.yaml  catalog
	ls -l _nodeconfig.yaml 
	$(KC) apply -f _nodeconfig.yaml 

# these may be mounted into each node of the cluster as required
catalog: cm/deltas3g.properties cm/deltas3.properties
	$(KC) delete configmap cm-deltas3g.properties cm-deltas3.properties --ignore-not-found
	$(KC) create configmap cm-deltas3g.properties --from-file=cm/deltas3g.properties
	$(KC) create configmap cm-deltas3.properties --from-file=cm/deltas3.properties

start: _coordinator.yaml _workers.yaml
	ls -l _coordinator.yaml _workers.yaml
	$(KC) apply -f _coordinator.yaml -f _workers.yaml

# the script waits for the coordinator to be ready before starting the port-forward
pf:
	tools/pf.sh

stop: _coordinator.yaml _workers.yaml
	ls -l _coordinator.yaml _workers.yaml
	$(KC) delete -f _coordinator.yaml -f _workers.yaml

bounce: _workers.yaml
	$(KC) rollout restart statefulset/coordinator statefulset/worker

# use this to examine how pods are scheduled across the nodes of the cluster
spread:
	$(KC) describe pod | grep Node: | sort

# the gw & vs resources are optional
ls:
#	minikube status
#	$(EC) get cluster --region $(REGION) -v 0
	$(KC) get cm,svc,deploy,statefulset,po
#	$(KC) get gw,vs

# invoke the packed-in CLI inside the coordinator node
cli:
	$(KC) exec coordinator-0 -it -- px-cli

nodecheck:
	$(KC) exec coordinator-0 -it -- px-cli --execute "SELECT * FROM system.runtime.nodes;"

psanity:
	$(KC) exec coordinator-0 -it -- px-cli < q/tpcds-sanity.sql

tversioncheck:
	$(KC) exec coordinator-0 -it -- ls -l /usr/local/px/plugin/delta/trino-delta-359.jar
	$(KC) exec worker-0 -it -- ls -l /usr/local/px/plugin/delta/trino-delta-359.jar

pversioncheck:
	$(KC) exec coordinator-0 -it -- ls -l /usr/local/px/plugin/delta/presto-delta-0.269-SNAPSHOT.jar
	$(KC) exec worker-0 -it -- ls -l /usr/local/px/plugin/delta/presto-delta-0.269-SNAPSHOT.jar

clean:
	$(KC) delete cm --all

bashc:
	$(KC) exec coordinator-0 -it -- bash

bashw0:
	$(KC) exec worker-0 -it -- bash

bashw1:
	$(KC) exec worker-1 -it -- bash

pshrink:
	$(KC) scale --replicas=1 statefulset/worker

pscale:
	$(KC) scale --replicas=10 statefulset/worker


q96:
	$(KC) exec coordinator-0 -it -- trino-cli < tpcds-q96.sql


# for shell-level nslookup to test network names inside the cluster
# resume using 'kubectl attach curl -c curl -i -t' command while the pod is running
rawshell:
	$(KC) run curl --image=radial/busyboxplus:curl -i --tty

resumeshell:
	$(KC) attach curl -c curl -i -t

# check worker0's node.properties for proper name association
worker0:
	$(KC) exec worker-0 -it -- cat /usr/local/px/etc/node.properties
	$(KC) exec worker-0 -it -- cat /usr/local/px/etc/config.properties
	$(KC) exec worker-0 -it -- cat /usr/local/px/etc/catalog/deltas3.properties
 
 # check coordinator's node.properties for proper name association
coord0:
	$(KC) exec coordinator-0 -it -- cat /usr/local/px/etc/node.properties
	$(KC) exec coordinator-0 -it -- cat /usr/local/px/etc/config.properties
	$(KC) exec coordinator-0 -it -- cat /usr/local/px/etc/catalog/deltas3.properties

