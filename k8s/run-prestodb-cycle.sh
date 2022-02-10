#!/usr/bin/env bash

VERSION=trial-0266-f
WORKERS=10

mkdir -p r/${VERSION}
sed s/ZZ/${VERSION}/ tools/collect.sh-tpl > r/${VERSION}/collect.sh
chmod +x r/${VERSION}/collect.sh

echo Use the web console to fetch the query ids to save the execution JSON.
echo Fill in the following:
ls -l r/${VERSION}/collect.sh

# set up the PrestoDB namespace 
make ns2 

# switch to the PrestoDB coordinator/workers
make def2 gop

# configure the env and credentials
make config awscred 

make start

# wait for the coordinator & worker to be ready
until [ $(kubectl get pod -l role=px-coord --output json | jq -r '.items[]| .status.containerStatuses[0].ready') = "true" ];
do
  sleep 10
done
until [ $(kubectl get pod -l role=px-work --output json | jq -r '.items[]| .status.containerStatuses[0].ready') = "true" ];
do
  sleep 10
done

# Wait for the 1 Presto worker. (We assume the coordinator is up since this is a Presto query.)
until [ $(make nodecheck | grep worker | wc -l ) = "1" ];
do
  sleep 60
done

# ----------------------
#  sf 1 & 10 on 1 node
# ----------------------
make cli < q/altquery4-sf1.sql  > r/${VERSION}/query4-1-1w.out
make cli < q/altquery4-sf10.sql > r/${VERSION}/query4-10-1w.out

# scale up the Kubernetes cluster
make kscale

# wait on EKS first
until [ $(kubectl get nodes -l role=px-work| grep Ready | wc -l) = "10" ];
do
  echo "AWS/EKS is scaling..."
  sleep 10
done

make pscale

# then Kubernetes
until [ $(kubectl get pod -l role=px-work | grep Running | wc -l ) = "10" ];
do
  sleep 10
done
until [ $(kubectl get statefulset/worker --output json | jq -r '.status.currentReplicas') = "10" ];
do
  sleep 1
done

# and finally Presto
until [ $(make nodecheck | grep worker | wc -l ) = "10" ];
do
  echo "Presto is scaling..."
  sleep 30
done

# ----------------------
#  sf 1, 10, & 1000 on 10 nodes
# ----------------------
make cli < q/altquery4-sf1.sql  > r/${VERSION}/query4-1-10w.out
make cli < q/altquery4-sf10.sql > r/${VERSION}/query4-10-10w.out
make cli < q/altquery4.sql      > r/${VERSION}/query4-10w.out

ls -l r/${VERSION}/*

echo Use the web console to fetch the query ideas and pull the execution JSON.
echo Fill in the following:
ls -l r/${VERSION}/collect.sh

# scale down our Presto workers 
make pshrink
# there doesn't seem to be a reasons to wait cuz the shrink doesn't respect the actual workload

# then shrink the worker's nodegroup
make kshrink
