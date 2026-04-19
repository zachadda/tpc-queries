-- Q45: Web Sales by Customer Demographics
SELECT ca_zip, ca_state, SUM(ws_sales_price)
FROM TPCDS_10GB.WEB_SALES, TPCDS_10GB.CUSTOMER, TPCDS_10GB.CUSTOMER_ADDRESS, TPCDS_10GB.DATE_DIM, TPCDS_10GB.ITEM
WHERE ws_bill_customer_sk = c_customer_sk AND c_current_addr_sk = ca_address_sk AND ws_item_sk = i_item_sk
AND (SUBSTR(ca_zip, 1, 5) IN ('85669', '86197', '88274', '83405', '86475', '85392', '85460', '80348', '81792') OR i_item_id IN (SELECT i_item_id FROM TPCDS_10GB.ITEM WHERE i_item_sk IN (2, 3, 5, 7, 11, 13, 17, 19, 23, 29)))
AND ws_sold_date_sk = d_date_sk AND d_qoy = 2 AND d_year = 2001
GROUP BY ca_zip, ca_state
ORDER BY ca_zip, ca_state LIMIT 100;
