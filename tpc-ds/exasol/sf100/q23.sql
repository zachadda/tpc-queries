-- Q23: Frequent Store Sales Customer
WITH frequent_ss_items AS (
  SELECT SUBSTR(i_item_desc, 1, 30) itemdesc, i_item_sk item_sk, d_date solddate, COUNT(*) cnt
  FROM TPCDS_100GB.STORE_SALES, TPCDS_100GB.DATE_DIM, TPCDS_100GB.ITEM
  WHERE ss_sold_date_sk = d_date_sk AND ss_item_sk = i_item_sk AND d_year IN (2000, 2000+1, 2000+2, 2000+3)
  GROUP BY SUBSTR(i_item_desc, 1, 30), i_item_sk, d_date
  HAVING COUNT(*) > 4
),
max_store_sales AS (
  SELECT MAX(csales) tpcds_cmax FROM (
    SELECT c_customer_sk, SUM(ss_quantity*ss_sales_price) csales
    FROM TPCDS_100GB.CUSTOMER, TPCDS_100GB.STORE_SALES, TPCDS_100GB.DATE_DIM
    WHERE c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk AND d_year IN (2000, 2000+1, 2000+2, 2000+3)
    GROUP BY c_customer_sk
  ) t
),
best_ss_customer AS (
  SELECT c_customer_sk, SUM(ss_quantity*ss_sales_price) ssales
  FROM TPCDS_100GB.CUSTOMER, TPCDS_100GB.STORE_SALES
  WHERE c_customer_sk = ss_customer_sk
  GROUP BY c_customer_sk
  HAVING SUM(ss_quantity*ss_sales_price) > (95.0/100.0) * (SELECT * FROM max_store_sales)
)
SELECT SUM(sales) total_sales FROM (
  SELECT cs_quantity*cs_list_price sales
  FROM TPCDS_100GB.CATALOG_SALES, TPCDS_100GB.DATE_DIM
  WHERE d_year = 2000 AND d_moy = 2 AND cs_sold_date_sk = d_date_sk
  AND cs_item_sk IN (SELECT item_sk FROM frequent_ss_items)
  AND cs_bill_customer_sk IN (SELECT c_customer_sk FROM best_ss_customer)
  UNION ALL
  SELECT ws_quantity*ws_list_price sales
  FROM TPCDS_100GB.WEB_SALES, TPCDS_100GB.DATE_DIM
  WHERE d_year = 2000 AND d_moy = 2 AND ws_sold_date_sk = d_date_sk
  AND ws_item_sk IN (SELECT item_sk FROM frequent_ss_items)
  AND ws_bill_customer_sk IN (SELECT c_customer_sk FROM best_ss_customer)
) t LIMIT 100;
