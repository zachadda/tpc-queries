-- Q16: Catalog Sales Duplicate Orders
SELECT COUNT(DISTINCT cs_order_number) AS order_count, SUM(cs_ext_ship_cost) AS total_shipping_cost, SUM(cs_net_profit) AS total_net_profit
FROM TPCDS_1GB.CATALOG_SALES cs1, TPCDS_1GB.DATE_DIM, TPCDS_1GB.CUSTOMER_ADDRESS, TPCDS_1GB.CALL_CENTER
WHERE d_date BETWEEN DATE '2002-02-01' AND DATE '2002-02-01' + INTERVAL '60' DAY
AND cs1.cs_ship_date_sk = d_date_sk AND cs1.cs_ship_addr_sk = ca_address_sk AND ca_state = 'GA'
AND cs1.cs_call_center_sk = cc_call_center_sk AND cc_county = 'Williamson County'
AND EXISTS (SELECT * FROM TPCDS_1GB.CATALOG_SALES cs2 WHERE cs1.cs_order_number = cs2.cs_order_number AND cs1.cs_warehouse_sk <> cs2.cs_warehouse_sk)
AND NOT EXISTS (SELECT * FROM TPCDS_1GB.CATALOG_RETURNS cr1 WHERE cs1.cs_order_number = cr1.cr_order_number)
ORDER BY order_count LIMIT 100;
