-- Q32: Catalog Excess Discount
SELECT SUM(cs_ext_discount_amt) AS excess_discount_amount
FROM TPCDS_100GB.CATALOG_SALES, TPCDS_100GB.ITEM, TPCDS_100GB.DATE_DIM
WHERE i_manufact_id = 977 AND i_item_sk = cs_item_sk
AND d_date BETWEEN DATE '2000-01-27' AND DATE '2000-01-27' + INTERVAL '90' DAY AND d_date_sk = cs_sold_date_sk
AND cs_ext_discount_amt > (
  SELECT 1.3 * AVG(cs_ext_discount_amt) FROM TPCDS_100GB.CATALOG_SALES, TPCDS_100GB.DATE_DIM
  WHERE cs_item_sk = i_item_sk AND d_date BETWEEN DATE '2000-01-27' AND DATE '2000-01-27' + INTERVAL '90' DAY AND d_date_sk = cs_sold_date_sk
)
LIMIT 100;
