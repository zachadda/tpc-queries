-- Q94: Web Sales Unique Orders
SELECT COUNT(DISTINCT ws_order_number) AS order_count, SUM(ws_ext_ship_cost) AS total_shipping_cost, SUM(ws_net_profit) AS total_net_profit
FROM TPCDS_10GB.WEB_SALES ws1, TPCDS_10GB.DATE_DIM, TPCDS_10GB.CUSTOMER_ADDRESS, TPCDS_10GB.WEB_SITE
WHERE d_date BETWEEN DATE '1999-02-01' AND DATE '1999-02-01' + INTERVAL '60' DAY
AND ws1.ws_ship_date_sk = d_date_sk AND ws1.ws_ship_addr_sk = ca_address_sk AND ca_state = 'IL'
AND ws1.ws_web_site_sk = web_site_sk AND web_company_name = 'pri'
AND EXISTS (SELECT * FROM TPCDS_10GB.WEB_SALES ws2 WHERE ws1.ws_order_number = ws2.ws_order_number AND ws1.ws_warehouse_sk <> ws2.ws_warehouse_sk)
AND NOT EXISTS (SELECT * FROM TPCDS_10GB.WEB_RETURNS wr1 WHERE ws1.ws_order_number = wr1.wr_order_number)
ORDER BY order_count LIMIT 100;
