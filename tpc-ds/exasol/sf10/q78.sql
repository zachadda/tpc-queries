-- Q78: Cross Channel Revenue
WITH ws AS (
  SELECT d_year AS ws_sold_year, ws_item_sk,
    ws_bill_customer_sk ws_customer_sk,
    SUM(ws_quantity) ws_qty, SUM(ws_wholesale_cost) ws_wc, SUM(ws_sales_price) ws_sp
  FROM TPCDS_10GB.WEB_SALES LEFT JOIN TPCDS_10GB.WEB_RETURNS ON wr_order_number = ws_order_number AND ws_item_sk = wr_item_sk
    JOIN TPCDS_10GB.DATE_DIM ON ws_sold_date_sk = d_date_sk
  WHERE wr_order_number IS NULL
  GROUP BY d_year, ws_item_sk, ws_bill_customer_sk
),
csales AS (
  SELECT d_year AS cs_sold_year, cs_item_sk,
    cs_bill_customer_sk cs_customer_sk,
    SUM(cs_quantity) cs_qty, SUM(cs_wholesale_cost) cs_wc, SUM(cs_sales_price) cs_sp
  FROM TPCDS_10GB.CATALOG_SALES LEFT JOIN TPCDS_10GB.CATALOG_RETURNS ON cr_order_number = cs_order_number AND cs_item_sk = cr_item_sk
    JOIN TPCDS_10GB.DATE_DIM ON cs_sold_date_sk = d_date_sk
  WHERE cr_order_number IS NULL
  GROUP BY d_year, cs_item_sk, cs_bill_customer_sk
),
ss AS (
  SELECT d_year AS ss_sold_year, ss_item_sk,
    ss_customer_sk,
    SUM(ss_quantity) ss_qty, SUM(ss_wholesale_cost) ss_wc, SUM(ss_sales_price) ss_sp
  FROM TPCDS_10GB.STORE_SALES LEFT JOIN TPCDS_10GB.STORE_RETURNS ON sr_ticket_number = ss_ticket_number AND ss_item_sk = sr_item_sk
    JOIN TPCDS_10GB.DATE_DIM ON ss_sold_date_sk = d_date_sk
  WHERE sr_ticket_number IS NULL
  GROUP BY d_year, ss_item_sk, ss_customer_sk
)
SELECT ss_sold_year, ss_item_sk, ss_customer_sk,
  ROUND(ss_qty / (COALESCE(ws_qty, 0) + COALESCE(cs_qty, 0)), 2) AS ratio,
  ss_qty store_qty, ss_wc store_wholesale_cost, ss_sp store_sales_price,
  COALESCE(ws_qty, 0) + COALESCE(cs_qty, 0) other_chan_qty,
  COALESCE(ws_wc, 0) + COALESCE(cs_wc, 0) other_chan_wholesale_cost,
  COALESCE(ws_sp, 0) + COALESCE(cs_sp, 0) other_chan_sales_price
FROM ss
  LEFT JOIN ws ON ws_sold_year = ss_sold_year AND ws_item_sk = ss_item_sk AND ws_customer_sk = ss_customer_sk
  LEFT JOIN csales ON cs_sold_year = ss_sold_year AND cs_item_sk = ss_item_sk AND cs_customer_sk = ss_customer_sk
WHERE (COALESCE(ws_qty, 0) > 0 OR COALESCE(cs_qty, 0) > 0) AND ss_sold_year = 2000
ORDER BY ss_sold_year, ss_item_sk, ss_customer_sk, ss_qty DESC, ss_wc DESC, ss_sp DESC,
  other_chan_qty, other_chan_wholesale_cost, other_chan_sales_price, ratio
LIMIT 100;
