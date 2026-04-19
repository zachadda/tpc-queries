-- Q77: Multi-Channel Profit
WITH ss AS (
  SELECT s_store_sk, SUM(ss_ext_sales_price) AS sales, SUM(ss_net_profit) AS profit
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND ss_store_sk = s_store_sk
  GROUP BY s_store_sk
),
sr AS (
  SELECT s_store_sk, SUM(sr_return_amt) AS returns_amt, SUM(sr_net_loss) AS profit_loss
  FROM TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE sr_returned_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND sr_store_sk = s_store_sk
  GROUP BY s_store_sk
),
csales AS (
  SELECT cs_call_center_sk, SUM(cs_ext_sales_price) AS sales, SUM(cs_net_profit) AS profit
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM
  WHERE cs_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY
  GROUP BY cs_call_center_sk
),
cret AS (
  SELECT cr_call_center_sk, SUM(cr_return_amount) AS returns_amt, SUM(cr_net_loss) AS profit_loss
  FROM TPCDS_1000GB.CATALOG_RETURNS, TPCDS_1000GB.DATE_DIM
  WHERE cr_returned_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY
  GROUP BY cr_call_center_sk
),
ws AS (
  SELECT wp_web_page_sk, SUM(ws_ext_sales_price) AS sales, SUM(ws_net_profit) AS profit
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.WEB_PAGE
  WHERE ws_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND ws_web_page_sk = wp_web_page_sk
  GROUP BY wp_web_page_sk
),
wr AS (
  SELECT wp_web_page_sk, SUM(wr_return_amt) AS returns_amt, SUM(wr_net_loss) AS profit_loss
  FROM TPCDS_1000GB.WEB_RETURNS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.WEB_PAGE
  WHERE wr_returned_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND wr_web_page_sk = wp_web_page_sk
  GROUP BY wp_web_page_sk
)
SELECT channel, id, SUM(sales) AS sales, SUM(returns_amt) AS returns_amt, SUM(profit) AS profit
FROM (
  SELECT 'store channel' AS channel, ss.s_store_sk AS id, sales, COALESCE(returns_amt, 0) AS returns_amt, (profit - COALESCE(profit_loss, 0)) AS profit FROM ss LEFT JOIN sr ON ss.s_store_sk = sr.s_store_sk
  UNION ALL
  SELECT 'catalog channel' AS channel, cs_call_center_sk AS id, sales, COALESCE(returns_amt, 0) AS returns_amt, (profit - COALESCE(profit_loss, 0)) AS profit FROM csales LEFT JOIN cret ON csales.cs_call_center_sk = cret.cr_call_center_sk
  UNION ALL
  SELECT 'web channel' AS channel, ws.wp_web_page_sk AS id, sales, COALESCE(returns_amt, 0) AS returns_amt, (profit - COALESCE(profit_loss, 0)) AS profit FROM ws LEFT JOIN wr ON ws.wp_web_page_sk = wr.wp_web_page_sk
) x
GROUP BY ROLLUP(channel, id)
ORDER BY channel, id LIMIT 100;
