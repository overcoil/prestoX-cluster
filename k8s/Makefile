NS=trino
ISTIO_NS=istio-system
K8S_CTX=trino


REGION=us-west-2

# ref: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
KVER=1.21
CLUSTER_NAME=trino-eks-benchmark
NGROUP=worker-nodes

# GP: 8 vCPU/32 Gi RAM
#NTYPE=t3.2xlarge

# GP: m4.2xlarge: 8 vCPU/32 Gi RAM; USD0.40/h
NTYPE=m4.2xlarge
NODES=2
MIN_NODES=2
MAX_NODES=5


# you must have 
AWS=aws
KC=kubectl
EC=eksctl
IC=istioctl

.phony=mk eks ns label unlabel default awscred gw vs start stop ls istio extern cli nodetest sanity clean rawshell resumeshell worker0 coord

# =====================================================

# AWS EKS for primary; the rename-context relies on eksctl setting the newly created context/cluster to the current 
eksup:
	$(EC) create cluster \
		--region $(REGION) --version $(KVER) --name $(CLUSTER_NAME) \
		--nodegroup-name $(NGROUP) --node-type $(NTYPE) --nodes $(NODES) --nodes-min $(MIN_NODES) --nodes-max $(MAX_NODES) --managed 

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

# incomplete command line for scaling the EKS cluster
kscale:
	$(EC) scale nodegroup --cluster trino2-eks-benchmark -n worker --nodes $(NODE) -

# review your vpcs
vpcs:
	aws --region $(REGION) ec2 describe-vpcs --output json | jq -r '.Vpcs[]| .VpcId + " " + .CidrBlock + " " + (.IsDefault|tostring)'

# review subnets in your vpcs
subnets:
	aws --region $(REGION) ec2 describe-subnets --output json | jq -r '.Subnets[]| .SubnetId + " " + .VpcId + " " + .AvailabilityZone + " " + .CidrBlock'


# =====================================================


# optional for local test/dev
mk:
	minikube start --memory 8192 --cpus 4
	

# =====================================================

ns:
	$(KC) create ns $(NS)



default:
	$(KC) config set-context --current --namespace=$(NS)

awscred:
	$(KC) -n $(NS) apply -f secret-awscred.yaml

start:
	$(KC) -n $(NS) apply -f coordinator.yaml -f workers.yaml

portforward:
	$(KC) port-forward coordinator-0 8080:8080

stop:
	$(KC) -n $(NS) delete -f coordinator.yaml -f workers.yaml

bounce:
	$(KC) -n $(NS) rollout restart statefulset/coordinator statefulset/worker

status:
	$(KC) config get-contexts
		
# the gw & vs resources are optional
ls:
#	minikube status
	$(EC) get cluster --region $(REGION) -v 0
	$(KC) -n $(NS) get secret,svc,deploy,statefulset,po
#	$(KC) -n $(NS) get gw,vs

# use the packed-in CLI inside the coordinator node
cli:
	$(KC) exec coordinator-0 -it -- trino-cli

nodecheck:
	$(KC) exec coordinator-0 -it -- trino-cli < node-check.sql

sanity:
	$(KC) exec coordinator-0 -it -- trino-cli < tpcds-sanity.sql

clean:
	$(KC) -n $(NS) delete secret,gw,vs --all

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
	$(KC) -n $(NS) apply -f service-gateway.yaml

vs:
	$(KC) -n $(NS) apply -f trino-cli-vs.yaml

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
	$(KC) exec worker-0 -it -- cat /usr/local/trino/etc/node.properties
 
 # check coordinator's node.properties for proper name association
coord:
	$(KC) exec coordinator-0 -it -- cat /usr/local/trino/etc/node.properties
