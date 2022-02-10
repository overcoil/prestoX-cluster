#!/usr/bin/env bash
# 
# Fetch a PrestoDB query log after execution
#

PX=localhost:8080

curl --no-progress-meter --user admin: http://${PX}/v1/query/${1}?pretty --output ${2}
tools/extract-summary.sh ${2}

