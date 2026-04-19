-- Q5: Store Web Catalog Sales by Region
WITH ssr AS (
  SELECT s_store_id, SUM(ss_ext_sales_price) AS sales, SUM(ss_net_profit) AS profit, COALESCE(SUM(sr_return_amt), 0) AS returns_amt, COALESCE(SUM(sr_net_loss), 0) AS profit_loss
  FROM TPCDS_100GB.STORE_SALES LEFT JOIN TPCDS_100GB.STORE_RETURNS ON ss_item_sk = sr_item_sk AND ss_ticket_number = sr_ticket_number,
    TPCDS_100GB.DATE_DIM, TPCDS_100GB.STORE
  WHERE ss_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '14' DAY AND ss_store_sk = s_store_sk
  GROUP BY s_store_id
),
csr AS (
  SELECT cp_catalog_page_id, SUM(cs_ext_sales_price) AS sales, SUM(cs_net_profit) AS profit, COALESCE(SUM(cr_return_amount), 0) AS returns_amt, COALESCE(SUM(cr_net_loss), 0) AS profit_loss
  FROM TPCDS_100GB.CATALOG_SALES LEFT JOIN TPCDS_100GB.CATALOG_RETURNS ON cs_item_sk = cr_item_sk AND cs_order_number = cr_order_number,
    TPCDS_100GB.DATE_DIM, TPCDS_100GB.CATALOG_PAGE
  WHERE cs_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '14' DAY AND cs_catalog_page_sk = cp_catalog_page_sk
  GROUP BY cp_catalog_page_id
),
wsr AS (
  SELECT web_site_id, SUM(ws_ext_sales_price) AS sales, SUM(ws_net_profit) AS profit, COALESCE(SUM(wr_return_amt), 0) AS returns_amt, COALESCE(SUM(wr_net_loss), 0) AS profit_loss
  FROM TPCDS_100GB.WEB_SALES LEFT JOIN TPCDS_100GB.WEB_RETURNS ON ws_item_sk = wr_item_sk AND ws_order_number = wr_order_number,
    TPCDS_100GB.DATE_DIM, TPCDS_100GB.WEB_SITE
  WHERE ws_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '14' DAY AND ws_web_site_sk = web_site_sk
  GROUP BY web_site_id
)
SELECT channel, id, SUM(sales) AS total_sales, SUM(returns_amt) AS total_returns, SUM(profit) AS total_profit
FROM (
  SELECT 'store channel' AS channel, 'store' || s_store_id AS id, sales, returns_amt, (profit - profit_loss) AS profit FROM ssr
  UNION ALL
  SELECT 'catalog channel' AS channel, 'catalog_page' || cp_catalog_page_id AS id, sales, returns_amt, (profit - profit_loss) AS profit FROM csr
  UNION ALL
  SELECT 'web channel' AS channel, 'web_site' || web_site_id AS id, sales, returns_amt, (profit - profit_loss) AS profit FROM wsr
) x
GROUP BY ROLLUP(channel, id)
ORDER BY channel, id LIMIT 100;
