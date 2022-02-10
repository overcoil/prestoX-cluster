WITH
  store_sales_sf10 AS (SELECT * FROM deltas3."$path$"."s3://tpc-datasets/tpcds-2.13/tpcds_sf10_delta/store_sales" ),
  date_dim AS (SELECT * FROM deltas3."$path$"."s3://tpc-datasets/tpcds_1000_dat_delta/date_dim" )

SELECT * FROM store_sales_sf10 store_sales

JOIN date_dim ON ss_sold_date_sk = d_date_sk 

WHERE d_year=1998 AND d_moy=7 AND d_dom=5
;

