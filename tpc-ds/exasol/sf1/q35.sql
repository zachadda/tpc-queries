-- Q35: Customer Demographics Join
SELECT ca_state, cd_gender, cd_marital_status, cd_dep_count, COUNT(*) cnt1, AVG(cd_dep_count) avg1, MAX(cd_dep_count) max1, SUM(cd_dep_count) sum1,
  cd_dep_employed_count, COUNT(*) cnt2, AVG(cd_dep_employed_count) avg2, MAX(cd_dep_employed_count) max2, SUM(cd_dep_employed_count) sum2,
  cd_dep_college_count, COUNT(*) cnt3, AVG(cd_dep_college_count) avg3, MAX(cd_dep_college_count) max3, SUM(cd_dep_college_count) sum3
FROM TPCDS_1GB.CUSTOMER c, TPCDS_1GB.CUSTOMER_ADDRESS ca, TPCDS_1GB.CUSTOMER_DEMOGRAPHICS
WHERE c.c_current_addr_sk = ca.ca_address_sk AND cd_demo_sk = c.c_current_cdemo_sk
AND EXISTS (SELECT * FROM TPCDS_1GB.STORE_SALES, TPCDS_1GB.DATE_DIM WHERE c.c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2002 AND d_qoy < 4)
AND (EXISTS (SELECT * FROM TPCDS_1GB.WEB_SALES, TPCDS_1GB.DATE_DIM WHERE c.c_customer_sk = ws_bill_customer_sk AND ws_sold_date_sk = d_date_sk AND d_year = 2002 AND d_qoy < 4)
  OR EXISTS (SELECT * FROM TPCDS_1GB.CATALOG_SALES, TPCDS_1GB.DATE_DIM WHERE c.c_customer_sk = cs_ship_customer_sk AND cs_sold_date_sk = d_date_sk AND d_year = 2002 AND d_qoy < 4))
GROUP BY ca_state, cd_gender, cd_marital_status, cd_dep_count, cd_dep_employed_count, cd_dep_college_count
ORDER BY ca_state, cd_gender, cd_marital_status, cd_dep_count, cd_dep_employed_count, cd_dep_college_count
LIMIT 100;
