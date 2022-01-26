#!/usr/bin/env bash
# 
# Iterate on one query:
#  1. run/save directly verbatim
#  2. derive an EXPLAIN variant & run/save that
#  3. derive an EXPLAIN ANALYZE variant & run/save

KC=/usr/local/bin/kubectl

set -o nounset
set -o errexit
set -o xtrace

if [[ $# -eq 1 ]]
then
  qbase=${1}
else
  qbase=thequery
fi

cat q/ex.sql q/${qbase}.sql > q/${qbase}-ex.sql
cat q/ex.sql q/an.sql q/${qbase}.sql > q/${qbase}-ex-an.sql

${KC} exec coordinator-0 -it -- px-cli < q/${qbase}.sql       > q/${qbase}.out

${KC} exec coordinator-0 -it -- px-cli < q/${qbase}-ex.sql    > q/${qbase}-ex.out

${KC} exec coordinator-0 -it -- px-cli < q/${qbase}-ex-an.sql > q/${qbase}-ex-an.out
