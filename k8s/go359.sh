#!/usr/bin/env bash

rm trino-coordinator.yaml trino-workers.yaml
ln -s px-manifests/trino-359-coordinator.yaml trino-coordinator.yaml
ln -s px-manifests/trino-359-workers.yaml trino-workers.yaml
ls -l trino-*.yaml

