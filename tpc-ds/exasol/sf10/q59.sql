-- Q59: Store Weekly Sales Ratio
WITH wss AS (
  SELECT d_week_seq,
    ss_store_sk,
    SUM(CASE WHEN d_day_name = 'Sunday' THEN ss_sales_price ELSE NULL END) sun_sales,
    SUM(CASE WHEN d_day_name = 'Monday' THEN ss_sales_price ELSE NULL END) mon_sales,
    SUM(CASE WHEN d_day_name = 'Tuesday' THEN ss_sales_price ELSE NULL END) tue_sales,
    SUM(CASE WHEN d_day_name = 'Wednesday' THEN ss_sales_price ELSE NULL END) wed_sales,
    SUM(CASE WHEN d_day_name = 'Thursday' THEN ss_sales_price ELSE NULL END) thu_sales,
    SUM(CASE WHEN d_day_name = 'Friday' THEN ss_sales_price ELSE NULL END) fri_sales,
    SUM(CASE WHEN d_day_name = 'Saturday' THEN ss_sales_price ELSE NULL END) sat_sales
  FROM TPCDS_10GB.STORE_SALES, TPCDS_10GB.DATE_DIM
  WHERE d_date_sk = ss_sold_date_sk
  GROUP BY d_week_seq, ss_store_sk
)
SELECT y1.s_store_name AS s_store_name1, y1.wk_seq AS d_week_seq1,
  y1.sun_sales1 / y2.sun_sales2 AS sun_ratio, y1.mon_sales1 / y2.mon_sales2 AS mon_ratio,
  y1.tue_sales1 / y2.tue_sales2 AS tue_ratio, y1.wed_sales1 / y2.wed_sales2 AS wed_ratio,
  y1.thu_sales1 / y2.thu_sales2 AS thu_ratio, y1.fri_sales1 / y2.fri_sales2 AS fri_ratio,
  y1.sat_sales1 / y2.sat_sales2 AS sat_ratio
FROM (
  SELECT s_store_name, wss.d_week_seq AS wk_seq, sun_sales AS sun_sales1, mon_sales AS mon_sales1, tue_sales AS tue_sales1, wed_sales AS wed_sales1, thu_sales AS thu_sales1, fri_sales AS fri_sales1, sat_sales AS sat_sales1
  FROM wss, TPCDS_10GB.STORE, TPCDS_10GB.DATE_DIM d
  WHERE d.d_week_seq = wss.d_week_seq AND ss_store_sk = s_store_sk AND d_month_seq BETWEEN 1212 AND 1212+11
) y1,
(SELECT s_store_id, wss.d_week_seq AS wk_seq, sun_sales AS sun_sales2, mon_sales AS mon_sales2, tue_sales AS tue_sales2, wed_sales AS wed_sales2, thu_sales AS thu_sales2, fri_sales AS fri_sales2, sat_sales AS sat_sales2
  FROM wss, TPCDS_10GB.STORE, TPCDS_10GB.DATE_DIM d
  WHERE d.d_week_seq = wss.d_week_seq AND ss_store_sk = s_store_sk AND d_month_seq BETWEEN 1212+12 AND 1212+23
) y2
WHERE y1.wk_seq = y2.wk_seq - 52
ORDER BY s_store_name1, d_week_seq1, sun_ratio LIMIT 100;
