-- Q2: Web Catalog Weekly Sales
WITH wscs AS (
  SELECT sold_date_sk, sales_price FROM (
    SELECT ws_sold_date_sk AS sold_date_sk, ws_ext_sales_price AS sales_price FROM TPCDS_100GB.WEB_SALES
    UNION ALL
    SELECT cs_sold_date_sk AS sold_date_sk, cs_ext_sales_price AS sales_price FROM TPCDS_100GB.CATALOG_SALES
  ) x
),
wswscs AS (
  SELECT d_week_seq, SUM(CASE WHEN d_day_name = 'Sunday' THEN sales_price ELSE NULL END) sun_sales,
    SUM(CASE WHEN d_day_name = 'Monday' THEN sales_price ELSE NULL END) mon_sales,
    SUM(CASE WHEN d_day_name = 'Tuesday' THEN sales_price ELSE NULL END) tue_sales,
    SUM(CASE WHEN d_day_name = 'Wednesday' THEN sales_price ELSE NULL END) wed_sales,
    SUM(CASE WHEN d_day_name = 'Thursday' THEN sales_price ELSE NULL END) thu_sales,
    SUM(CASE WHEN d_day_name = 'Friday' THEN sales_price ELSE NULL END) fri_sales,
    SUM(CASE WHEN d_day_name = 'Saturday' THEN sales_price ELSE NULL END) sat_sales
  FROM wscs, TPCDS_100GB.DATE_DIM WHERE d_date_sk = sold_date_sk GROUP BY d_week_seq
)
SELECT y1.d_week_seq,
  ROUND(y1.sun_sales1/y2.sun_sales2, 2) AS sun_ratio, ROUND(y1.mon_sales1/y2.mon_sales2, 2) AS mon_ratio,
  ROUND(y1.tue_sales1/y2.tue_sales2, 2) AS tue_ratio, ROUND(y1.wed_sales1/y2.wed_sales2, 2) AS wed_ratio,
  ROUND(y1.thu_sales1/y2.thu_sales2, 2) AS thu_ratio, ROUND(y1.fri_sales1/y2.fri_sales2, 2) AS fri_ratio,
  ROUND(y1.sat_sales1/y2.sat_sales2, 2) AS sat_ratio
FROM (SELECT wswscs.d_week_seq AS d_week_seq, sun_sales AS sun_sales1, mon_sales AS mon_sales1, tue_sales AS tue_sales1, wed_sales AS wed_sales1, thu_sales AS thu_sales1, fri_sales AS fri_sales1, sat_sales AS sat_sales1 FROM wswscs, TPCDS_100GB.DATE_DIM d1 WHERE d1.d_week_seq = wswscs.d_week_seq AND d1.d_year = 2001) y1,
(SELECT wswscs.d_week_seq AS d_week_seq, sun_sales AS sun_sales2, mon_sales AS mon_sales2, tue_sales AS tue_sales2, wed_sales AS wed_sales2, thu_sales AS thu_sales2, fri_sales AS fri_sales2, sat_sales AS sat_sales2 FROM wswscs, TPCDS_100GB.DATE_DIM d2 WHERE d2.d_week_seq = wswscs.d_week_seq AND d2.d_year = 2001 + 1) y2
WHERE y1.d_week_seq = y2.d_week_seq - 53
ORDER BY y1.d_week_seq LIMIT 100;
