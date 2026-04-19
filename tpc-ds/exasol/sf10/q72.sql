-- Q72: Catalog Inventory Promo
SELECT i_item_desc, w_warehouse_name, d1.d_week_seq,
  SUM(CASE WHEN p_promo_sk IS NULL THEN 1 ELSE 0 END) no_promo,
  SUM(CASE WHEN p_promo_sk IS NOT NULL THEN 1 ELSE 0 END) promo,
  COUNT(*) total_cnt
FROM TPCDS_10GB.CATALOG_SALES
  JOIN TPCDS_10GB.INVENTORY ON cs_item_sk = inv_item_sk
  JOIN TPCDS_10GB.WAREHOUSE ON w_warehouse_sk = inv_warehouse_sk
  JOIN TPCDS_10GB.ITEM ON i_item_sk = cs_item_sk
  JOIN TPCDS_10GB.CUSTOMER_DEMOGRAPHICS ON cs_bill_cdemo_sk = cd_demo_sk
  JOIN TPCDS_10GB.HOUSEHOLD_DEMOGRAPHICS ON cs_bill_hdemo_sk = hd_demo_sk
  JOIN TPCDS_10GB.DATE_DIM d1 ON cs_sold_date_sk = d1.d_date_sk
  JOIN TPCDS_10GB.DATE_DIM d2 ON inv_date_sk = d2.d_date_sk
  JOIN TPCDS_10GB.DATE_DIM d3 ON cs_ship_date_sk = d3.d_date_sk
  LEFT OUTER JOIN TPCDS_10GB.PROMOTION ON cs_promo_sk = p_promo_sk
WHERE d1.d_week_seq = d2.d_week_seq AND inv_quantity_on_hand < cs_quantity
AND d3.d_date > d1.d_date + INTERVAL '5' DAY AND hd_buy_potential = '>10000' AND d1.d_year = 1999 AND cd_marital_status = 'D'
GROUP BY i_item_desc, w_warehouse_name, d1.d_week_seq
ORDER BY total_cnt DESC, i_item_desc, w_warehouse_name, d1.d_week_seq LIMIT 100;
