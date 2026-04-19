-- Q92: Web Sales Excess Discount
SELECT SUM(ws_ext_discount_amt) AS excess_discount_amount
FROM TPCDS_10GB.WEB_SALES, TPCDS_10GB.ITEM, TPCDS_10GB.DATE_DIM
WHERE i_manufact_id = 350 AND i_item_sk = ws_item_sk
AND d_date BETWEEN DATE '2000-01-27' AND DATE '2000-01-27' + INTERVAL '90' DAY AND d_date_sk = ws_sold_date_sk
AND ws_ext_discount_amt > (
  SELECT 1.3 * AVG(ws_ext_discount_amt) FROM TPCDS_10GB.WEB_SALES, TPCDS_10GB.DATE_DIM
  WHERE ws_item_sk = i_item_sk AND d_date BETWEEN DATE '2000-01-27' AND DATE '2000-01-27' + INTERVAL '90' DAY AND d_date_sk = ws_sold_date_sk
)
ORDER BY SUM(ws_ext_discount_amt) LIMIT 100;
