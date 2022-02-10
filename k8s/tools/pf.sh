#!/usr/bin/env bash
until [ $(kubectl get po| grep coordinator | cut -w -f 3) = "Running" ];
do
  sleep 10
done

kubectl port-forward coordinator-0 8080:8080
