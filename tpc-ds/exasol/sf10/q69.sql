-- Q69: Customer Channel Activity
SELECT cd_gender, cd_marital_status, cd_education_status, COUNT(*) cnt1, cd_purchase_estimate, COUNT(*) cnt2, cd_credit_rating, COUNT(*) cnt3
FROM TPCDS_10GB.CUSTOMER c, TPCDS_10GB.CUSTOMER_ADDRESS ca, TPCDS_10GB.CUSTOMER_DEMOGRAPHICS
WHERE c.c_current_addr_sk = ca.ca_address_sk AND ca_state IN ('KY', 'GA', 'NM') AND cd_demo_sk = c.c_current_cdemo_sk
AND EXISTS (SELECT * FROM TPCDS_10GB.STORE_SALES, TPCDS_10GB.DATE_DIM WHERE c.c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy BETWEEN 4 AND 4+2)
AND NOT EXISTS (SELECT * FROM TPCDS_10GB.WEB_SALES, TPCDS_10GB.DATE_DIM WHERE c.c_customer_sk = ws_bill_customer_sk AND ws_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy BETWEEN 4 AND 4+2)
AND NOT EXISTS (SELECT * FROM TPCDS_10GB.CATALOG_SALES, TPCDS_10GB.DATE_DIM WHERE c.c_customer_sk = cs_ship_customer_sk AND cs_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy BETWEEN 4 AND 4+2)
GROUP BY cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, cd_credit_rating
ORDER BY cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, cd_credit_rating
LIMIT 100;
