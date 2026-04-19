-- Q61: Promotional Sales Analysis
SELECT promotions, total, CAST(promotions AS DECIMAL(15,4))/CAST(total AS DECIMAL(15,4))*100
FROM (
  SELECT SUM(ss_ext_sales_price) promotions
  FROM TPCDS_1GB.STORE_SALES, TPCDS_1GB.STORE, TPCDS_1GB.PROMOTION, TPCDS_1GB.DATE_DIM, TPCDS_1GB.CUSTOMER, TPCDS_1GB.CUSTOMER_ADDRESS, TPCDS_1GB.ITEM
  WHERE ss_sold_date_sk = d_date_sk AND ss_store_sk = s_store_sk AND ss_promo_sk = p_promo_sk AND ss_customer_sk = c_customer_sk AND ca_address_sk = c_current_addr_sk AND ss_item_sk = i_item_sk
  AND ca_gmt_offset = -5 AND i_category = 'Jewelry' AND (p_channel_dmail = 'Y' OR p_channel_email = 'Y' OR p_channel_tv = 'Y') AND s_gmt_offset = -5 AND d_year = 1998 AND d_moy = 11
) promotional_sales,
(SELECT SUM(ss_ext_sales_price) total
  FROM TPCDS_1GB.STORE_SALES, TPCDS_1GB.STORE, TPCDS_1GB.DATE_DIM, TPCDS_1GB.CUSTOMER, TPCDS_1GB.CUSTOMER_ADDRESS, TPCDS_1GB.ITEM
  WHERE ss_sold_date_sk = d_date_sk AND ss_store_sk = s_store_sk AND ss_customer_sk = c_customer_sk AND ca_address_sk = c_current_addr_sk AND ss_item_sk = i_item_sk
  AND ca_gmt_offset = -5 AND i_category = 'Jewelry' AND s_gmt_offset = -5 AND d_year = 1998 AND d_moy = 11
) all_sales
ORDER BY promotions, total LIMIT 100;
