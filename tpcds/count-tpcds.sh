#!/usr/bin/env bash


function count_table() {
  echo ${1}
  aws s3 --profile dbc2 ls --recursive s3://tpc-datasets/tpcds_1000_dat_delta/${1} | grep parquet | wc -l
}

for t in `cat tables.txt`
do
  count_table ${t}
done
