-- Q65: Store Item Revenue
SELECT s_store_name, i_item_desc, sc.revenue, i_current_price, i_wholesale_cost, i_brand
FROM TPCDS_100GB.STORE, TPCDS_100GB.ITEM,
  (SELECT ss_store_sk, ss_item_sk, SUM(ss_sales_price) AS revenue
   FROM TPCDS_100GB.STORE_SALES, TPCDS_100GB.DATE_DIM
   WHERE ss_sold_date_sk = d_date_sk AND d_month_seq BETWEEN 1176 AND 1176+11
   GROUP BY ss_store_sk, ss_item_sk
  ) sc,
  (SELECT ss_store_sk, AVG(revenue) AS ave
   FROM (SELECT ss_store_sk, ss_item_sk, SUM(ss_sales_price) AS revenue
         FROM TPCDS_100GB.STORE_SALES, TPCDS_100GB.DATE_DIM
         WHERE ss_sold_date_sk = d_date_sk AND d_month_seq BETWEEN 1176 AND 1176+11
         GROUP BY ss_store_sk, ss_item_sk) sa
   GROUP BY ss_store_sk
  ) sb
WHERE s_store_sk = sc.ss_store_sk AND sc.ss_store_sk = sb.ss_store_sk AND sc.revenue <= 0.1 * sb.ave AND s_store_sk = sc.ss_store_sk AND i_item_sk = sc.ss_item_sk
ORDER BY s_store_name, i_item_desc LIMIT 100;
