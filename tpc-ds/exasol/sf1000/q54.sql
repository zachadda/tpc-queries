-- Q54: Web Store Customer Reach
WITH my_customers AS (
  SELECT DISTINCT c_customer_sk, c_current_addr_sk
  FROM (
    SELECT cs_sold_date_sk sold_date_sk, cs_bill_customer_sk customer_sk, cs_item_sk item_sk
    FROM TPCDS_1000GB.CATALOG_SALES
    UNION ALL
    SELECT ws_sold_date_sk sold_date_sk, ws_bill_customer_sk customer_sk, ws_item_sk item_sk
    FROM TPCDS_1000GB.WEB_SALES
  ) cs_or_ws_sales, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER
  WHERE sold_date_sk = d_date_sk AND item_sk = i_item_sk AND i_category = 'Women' AND i_class = 'maternity'
  AND c_customer_sk = cs_or_ws_sales.customer_sk AND d_moy = 12 AND d_year = 1998
),
my_revenue AS (
  SELECT c_customer_sk, SUM(ss_ext_sales_price) AS revenue
  FROM my_customers, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.STORE, TPCDS_1000GB.DATE_DIM
  WHERE c_current_addr_sk = ca_address_sk AND ca_county = s_county AND ca_state = s_state
  AND ss_sold_date_sk = d_date_sk AND c_customer_sk = ss_customer_sk AND d_month_seq BETWEEN (SELECT DISTINCT d_month_seq+1 FROM TPCDS_1000GB.DATE_DIM WHERE d_year = 1998 AND d_moy = 12) AND (SELECT DISTINCT d_month_seq+3 FROM TPCDS_1000GB.DATE_DIM WHERE d_year = 1998 AND d_moy = 12)
  GROUP BY c_customer_sk
)
SELECT COUNT(*) AS customer_count, SUM(revenue) AS total_revenue FROM (
  SELECT c_customer_sk, SUM(revenue) AS revenue FROM my_revenue GROUP BY c_customer_sk
) t
LIMIT 100;
