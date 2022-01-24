WITH
  store_sales AS (SELECT * FROM deltas3."$path$"."s3://tpc-datasets/tpcds_1000_dat_delta/store_sales" ),
  item AS (SELECT * FROM deltas3."$path$"."s3://tpc-datasets/tpcds_1000_dat_delta/item" ),
  date_dim AS (SELECT * FROM deltas3."$path$"."s3://tpc-datasets/tpcds_1000_dat_delta/date_dim" )

SELECT * FROM store_sales

JOIN date_dim ON ss_sold_date_sk = d_date_sk 
JOIN item ON ss_item_sk = i_item_sk

WHERE d_date_sk = 2451000
 AND i_color = 'chocolate' AND i_size = 'small'


;

