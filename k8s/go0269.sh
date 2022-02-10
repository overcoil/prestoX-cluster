#!/usr/bin/env bash

rm prestodb-coordinator.yaml prestodb-workers.yaml
ln -s px-manifests/prestodb-0.269-coordinator.yaml prestodb-coordinator.yaml
ln -s px-manifests/prestodb-0.269-workers.yaml prestodb-workers.yaml
ls -l prestodb-*.yaml

