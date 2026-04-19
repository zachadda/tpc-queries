-- Q84: Customer Income Demographics
SELECT c_customer_id AS customer_id, COALESCE(c_last_name, '') || ', ' || COALESCE(c_first_name, '') AS customername
FROM TPCDS_1GB.CUSTOMER, TPCDS_1GB.CUSTOMER_ADDRESS, TPCDS_1GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1GB.INCOME_BAND, TPCDS_1GB.STORE_RETURNS
WHERE ca_city = 'Edgewood' AND c_current_addr_sk = ca_address_sk AND ib_lower_bound >= 38128 AND ib_upper_bound <= 38128+50000
AND ib_income_band_sk = hd_income_band_sk AND cd_demo_sk = c_current_cdemo_sk AND hd_demo_sk = c_current_hdemo_sk AND sr_cdemo_sk = cd_demo_sk
ORDER BY c_customer_id LIMIT 100;
