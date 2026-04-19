-- Q33: Manufacturer Sales Channel
SELECT i_manufact_id, SUM(total_sales) total_sales FROM (
  SELECT i_manufact_id, SUM(ss_ext_sales_price) total_sales
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_manufact_id IN (SELECT i_manufact_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Electronics'))
  AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 5
  AND ss_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_manufact_id
  UNION ALL
  SELECT i_manufact_id, SUM(cs_ext_sales_price) total_sales
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_manufact_id IN (SELECT i_manufact_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Electronics'))
  AND cs_item_sk = i_item_sk AND cs_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 5
  AND cs_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_manufact_id
  UNION ALL
  SELECT i_manufact_id, SUM(ws_ext_sales_price) total_sales
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_manufact_id IN (SELECT i_manufact_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Electronics'))
  AND ws_item_sk = i_item_sk AND ws_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 5
  AND ws_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_manufact_id
) tmp1
GROUP BY i_manufact_id
ORDER BY total_sales LIMIT 100;
