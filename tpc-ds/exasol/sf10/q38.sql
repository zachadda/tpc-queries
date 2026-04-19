-- Q38: Customer Cross Channel
SELECT COUNT(*) FROM (
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_10GB.STORE_SALES, TPCDS_10GB.DATE_DIM, TPCDS_10GB.CUSTOMER
  WHERE store_sales.ss_sold_date_sk = date_dim.d_date_sk AND store_sales.ss_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
  INTERSECT
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_10GB.CATALOG_SALES, TPCDS_10GB.DATE_DIM, TPCDS_10GB.CUSTOMER
  WHERE catalog_sales.cs_sold_date_sk = date_dim.d_date_sk AND catalog_sales.cs_bill_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
  INTERSECT
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_10GB.WEB_SALES, TPCDS_10GB.DATE_DIM, TPCDS_10GB.CUSTOMER
  WHERE web_sales.ws_sold_date_sk = date_dim.d_date_sk AND web_sales.ws_bill_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
) hot_cust
LIMIT 100;
