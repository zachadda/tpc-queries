-- Q99: Catalog Ship Mode Warehouse
SELECT SUBSTR(w_warehouse_name, 1, 20) wh_name, sm_type, cc_name,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk <= 30 THEN 1 ELSE 0 END) AS days_30,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk > 30 AND cs_ship_date_sk - cs_sold_date_sk <= 60 THEN 1 ELSE 0 END) AS days_31_60,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk > 60 AND cs_ship_date_sk - cs_sold_date_sk <= 90 THEN 1 ELSE 0 END) AS days_61_90,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk > 90 AND cs_ship_date_sk - cs_sold_date_sk <= 120 THEN 1 ELSE 0 END) AS days_91_120,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk > 120 THEN 1 ELSE 0 END) AS days_gt120
FROM TPCDS_10GB.CATALOG_SALES, TPCDS_10GB.WAREHOUSE, TPCDS_10GB.SHIP_MODE, TPCDS_10GB.CALL_CENTER, TPCDS_10GB.DATE_DIM
WHERE d_month_seq BETWEEN 1200 AND 1200+11 AND cs_ship_date_sk = d_date_sk AND cs_warehouse_sk = w_warehouse_sk AND cs_ship_mode_sk = sm_ship_mode_sk AND cs_call_center_sk = cc_call_center_sk
GROUP BY SUBSTR(w_warehouse_name, 1, 20), sm_type, cc_name
ORDER BY SUBSTR(w_warehouse_name, 1, 20), sm_type, cc_name LIMIT 100;
