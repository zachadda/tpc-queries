-- Q56: Store Catalog Web by Zip
SELECT i_item_id, SUM(total_sales) total_sales FROM (
  SELECT i_item_id, SUM(ss_ext_sales_price) total_sales
  FROM TPCDS_10GB.STORE_SALES, TPCDS_10GB.DATE_DIM, TPCDS_10GB.CUSTOMER_ADDRESS, TPCDS_10GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_10GB.ITEM WHERE i_color IN ('slate', 'blanched', 'burnished'))
  AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 2
  AND ss_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
  UNION ALL
  SELECT i_item_id, SUM(cs_ext_sales_price) total_sales
  FROM TPCDS_10GB.CATALOG_SALES, TPCDS_10GB.DATE_DIM, TPCDS_10GB.CUSTOMER_ADDRESS, TPCDS_10GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_10GB.ITEM WHERE i_color IN ('slate', 'blanched', 'burnished'))
  AND cs_item_sk = i_item_sk AND cs_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 2
  AND cs_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
  UNION ALL
  SELECT i_item_id, SUM(ws_ext_sales_price) total_sales
  FROM TPCDS_10GB.WEB_SALES, TPCDS_10GB.DATE_DIM, TPCDS_10GB.CUSTOMER_ADDRESS, TPCDS_10GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_10GB.ITEM WHERE i_color IN ('slate', 'blanched', 'burnished'))
  AND ws_item_sk = i_item_sk AND ws_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 2
  AND ws_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
) tmp1
GROUP BY i_item_id
ORDER BY total_sales, i_item_id LIMIT 100;
