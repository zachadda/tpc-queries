-- Q96: Store Sales Count Time
SELECT COUNT(*)
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk
AND time_dim.t_hour = 20 AND time_dim.t_minute >= 30 AND household_demographics.hd_dep_count = 7
AND store.s_store_name = 'ese'
ORDER BY COUNT(*) LIMIT 100;
