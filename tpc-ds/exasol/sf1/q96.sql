-- Q96: Store Sales Count Time
SELECT COUNT(*)
FROM TPCDS_1GB.STORE_SALES, TPCDS_1GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1GB.TIME_DIM, TPCDS_1GB.STORE
WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk
AND time_dim.t_hour = 20 AND time_dim.t_minute >= 30 AND household_demographics.hd_dep_count = 7
AND store.s_store_name = 'ese'
ORDER BY COUNT(*) LIMIT 100;
