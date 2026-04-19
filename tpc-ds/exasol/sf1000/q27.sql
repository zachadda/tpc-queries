-- Q27: Store Sales by State Item
SELECT i_item_id, s_state,
  GROUPING(s_state) g_state,
  AVG(ss_quantity) agg1, AVG(ss_list_price) agg2, AVG(ss_coupon_amt) agg3, AVG(ss_sales_price) agg4
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM
WHERE ss_sold_date_sk = d_date_sk AND ss_item_sk = i_item_sk AND ss_store_sk = s_store_sk AND ss_cdemo_sk = cd_demo_sk
AND cd_gender = 'M' AND cd_marital_status = 'S' AND cd_education_status = 'College'
AND d_year = 2002 AND s_state IN ('TN', 'SD', 'AL', 'SC', 'OH', 'LA')
GROUP BY ROLLUP(i_item_id, s_state)
ORDER BY i_item_id, s_state LIMIT 100;
