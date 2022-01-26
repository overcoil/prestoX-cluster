#
# Makefile for operating a Presto cluster in Kubernetes
#
# NB: "px" refers to the Presto in the communal sense of either forks: "PrestoDB" or "Trino"
#
# Override this as required;
# If one is using AWS/EKS, refer to the optional cluster-eks.yaml as required.
#

REGION=us-west-2
CLUSTER_NAME=px-benchmark
K8S_CTX=px
NS1=trino
NS2=prestodb
NS=$(NS1)

# GP: m4.2xlarge:  8 vCPU/32 Gi RAM; USD0.40/h
# GP: m4.4xlarge: 16 vCPU/64 Gi RAM; USD0.80/h
NODES=2
NTYPE=m4.4xlarge
NGROUP=worker-nodes
MIN_NODES=2
MAX_NODES=5

# add --profile yourprofile if required
AWS=aws --profile default

#EC=AWS_PROFILE=eks.min eksctl
EC=eksctl 

KC=kubectl
IC=istioctl
ISTIO_NS=istio-system

# ref: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
KVER=1.21

.phony=mk ns1 ns2 def1 def2 go1 go2 \
	awscred configproperties eksup eksdown dryrun eksdescribe kscale vpcs subnets \
	start stop pf bounce \
	cli nodetest sanity clean rawshell resumeshell \
	istio label unlabel gw vs extern \
	bashc bashw0 bashw1 \
	shrink scale3 scale10 scale20 q96



# =====================================================

# AWS EKS for primary; the rename-context relies on eksctl setting the newly created context/cluster to the current 
eksup:
# var 1: 
#	$(EC) create cluster --version $(KVER) \
#		--region $(REGION) --name $(CLUSTER_NAME) \
#		--nodegroup-name $(NGROUP) --node-type $(NTYPE) --nodes $(NODES) --nodes-min $(MIN_NODES) --nodes-max $(MAX_NODES) --managed 

# var 2: use cluster-eks.yaml to specify all parameters
	$(EC) create cluster -f cluster-eks.yaml  
	# do a version check cuz the -f option above has option to specify KVER
	$(AWS) eks describe-cluster --name $(CLUSTER_NAME) --output json | jq -r '.cluster.version'

    # Use back-ticks for subshell because $(...) notation is used by make
	$(KC) config rename-context `$(KC) config current-context` $(K8S_CTX) 

dryrun:
	$(EC) create cluster --dry-run \
		--region $(REGION) --version $(KVER) --name $(CLUSTER_NAME) \
		--nodegroup-name $(NGROUP) --node-type $(NTYPE) --nodes $(NODES) --nodes-min $(MIN_NODES) --nodes-max $(MAX_NODES) --managed 

# you can also delete just the nodegroup
eksdown:
	$(EC) delete cluster --name $(CLUSTER_NAME) --region $(REGION)
	$(KC) config delete-context $(K8S_CTX) 

eksdescribe:
	$(AWS) eks describe-cluster --name $(CLUSTER_NAME) --output json
	$(AWS) describe-instances --output json

# incomplete command line for scaling the EKS cluster
kscale:
	$(EC) scale nodegroup --cluster trino2-eks-benchmark -n worker --nodes $(NODE) -

# review your vpcs
vpcs:
	$(AWS) --region $(REGION) ec2 describe-vpcs --output json | jq -r '.Vpcs[]| .VpcId + " " + .CidrBlock + " " + (.IsDefault|tostring)'

# review subnets in your vpcs
subnets:
	$(AWS) --region $(REGION) ec2 describe-subnets --output json | jq -r '.Subnets[]| .SubnetId + " " + .VpcId + " " + .AvailabilityZone + " " + .CidrBlock'


# =====================================================


# optional for local test/dev
mk:
	minikube start --memory 8192 --cpus 4
	

# =====================================================

ns1:
	$(KC) create ns $(NS1)

ns2:
	$(KC) create ns $(NS2)

def1:
	$(KC) config set-context --current --namespace=$(NS1)
	ls -l _coordinator.yaml _workers.yaml

def2:
	$(KC) config set-context --current --namespace=$(NS2)
	ls -l _coordinator.yaml _workers.yaml

got:
	rm -f _coordinator.yaml _workers.yaml
	ln -s trino-coordinator.yaml _coordinator.yaml
	ln -s trino-workers.yaml _workers.yaml
	
gop:
	rm -f _coordinator.yaml _workers.yaml
	ln -s prestodb-coordinator.yaml _coordinator.yaml
	ln -s prestoDB-workers.yaml _workers.yaml

awscred: _awscred.yaml
	ls -l _awscred.yaml
	$(KC) apply -f _awscred.yaml

config: _config.yaml
	ls -l _config.yaml
	$(KC) apply -f _config.yaml

start: _coordinator.yaml _workers.yaml
	ls -l _coordinator.yaml _workers.yaml
	$(KC) apply -f _coordinator.yaml -f _workers.yaml

pf:
	$(KC) port-forward coordinator-0 8080:8080

stop: _coordinator.yaml _workers.yaml
	ls -l _coordinator.yaml _workers.yaml
	$(KC) delete -f _coordinator.yaml -f _workers.yaml

bounce: _workers.yaml
	$(KC) rollout restart statefulset/coordinator statefulset/worker

statust:
	$(KC) config get-contexts
		
# the gw & vs resources are optional
ls:
#	minikube status
#	$(EC) get cluster --region $(REGION) -v 0
	$(KC) get cm,secret,svc,deploy,statefulset,po
#	$(KC) get gw,vs

# use the packed-in CLI inside the coordinator node
cli:
	$(KC) exec coordinator-0 -it -- px-cli

nodecheck:
	$(KC) exec coordinator-0 -it -- px-cli < q/node-check.sql

sanity:
	$(KC) exec coordinator-0 -it -- px-cli < q/tpcds-sanity.sql

clean:
	$(KC) delete secret,gw,vs --all

bashc:
	$(KC) exec coordinator-0 -it -- bash

bashw0:
	$(KC) exec worker-0 -it -- bash

bashw1:
	$(KC) exec worker-1 -it -- bash

shrink:
	$(KC) scale --replicas=2 statefulset/worker

scale3:
	$(KC) scale --replicas=3 statefulset/worker

scale10:
	$(KC) scale --replicas=10 statefulset/worker

scale20:
	$(KC) scale --replicas=20 statefulset/worker


q96:
	$(KC) exec coordinator-0 -it -- trino-cli < tpcds-q96.sql

# =====================================================
# istio experiments
label:
	$(KC) label ns $(NS) istio-injection=enabled

unlabel:
	$(KC) label ns $(NS) istio-injection-

# Install Istio
istio:
	$(IC) install -y --set profile=demo --set hub=gcr.io/istio-release 


# =====================================================
# gateway 
gw:
	$(KC) apply -f service-gateway.yaml

vs:
	$(KC) apply -f trino-cli-vs.yaml

# get public access
extern:
	$(KC) -n $(ISTIO_NS) get svc istio-ingressgateway


# =====================================================

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

