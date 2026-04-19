-- TPC-DS All Queries - TPCDS_1000GB
OPEN SCHEMA TPCDS_1000GB;

-- Q1: Store Returns Customer
WITH customer_total_return AS (
  SELECT sr_customer_sk AS ctr_customer_sk, sr_store_sk AS ctr_store_sk, SUM(sr_return_amt) AS ctr_total_return
  FROM TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.DATE_DIM
  WHERE sr_returned_date_sk = d_date_sk AND d_year = 2000
  GROUP BY sr_customer_sk, sr_store_sk
)
SELECT c_customer_id
FROM customer_total_return ctr1, TPCDS_1000GB.STORE, TPCDS_1000GB.CUSTOMER
WHERE ctr1.ctr_total_return > (
  SELECT AVG(ctr_total_return) * 1.2 FROM customer_total_return ctr2 WHERE ctr1.ctr_store_sk = ctr2.ctr_store_sk
)
AND s_store_sk = ctr1.ctr_store_sk AND s_state = 'TN'
AND ctr1.ctr_customer_sk = c_customer_sk
ORDER BY c_customer_id LIMIT 100;

-- Q2: Web Catalog Weekly Sales
WITH wscs AS (
  SELECT sold_date_sk, sales_price FROM (
    SELECT ws_sold_date_sk AS sold_date_sk, ws_ext_sales_price AS sales_price FROM TPCDS_1000GB.WEB_SALES
    UNION ALL
    SELECT cs_sold_date_sk AS sold_date_sk, cs_ext_sales_price AS sales_price FROM TPCDS_1000GB.CATALOG_SALES
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
  FROM wscs, TPCDS_1000GB.DATE_DIM WHERE d_date_sk = sold_date_sk GROUP BY d_week_seq
)
SELECT y1.d_week_seq,
  ROUND(y1.sun_sales1/y2.sun_sales2, 2) AS sun_ratio, ROUND(y1.mon_sales1/y2.mon_sales2, 2) AS mon_ratio,
  ROUND(y1.tue_sales1/y2.tue_sales2, 2) AS tue_ratio, ROUND(y1.wed_sales1/y2.wed_sales2, 2) AS wed_ratio,
  ROUND(y1.thu_sales1/y2.thu_sales2, 2) AS thu_ratio, ROUND(y1.fri_sales1/y2.fri_sales2, 2) AS fri_ratio,
  ROUND(y1.sat_sales1/y2.sat_sales2, 2) AS sat_ratio
FROM (SELECT wswscs.d_week_seq AS d_week_seq, sun_sales AS sun_sales1, mon_sales AS mon_sales1, tue_sales AS tue_sales1, wed_sales AS wed_sales1, thu_sales AS thu_sales1, fri_sales AS fri_sales1, sat_sales AS sat_sales1 FROM wswscs, TPCDS_1000GB.DATE_DIM d1 WHERE d1.d_week_seq = wswscs.d_week_seq AND d1.d_year = 2001) y1,
(SELECT wswscs.d_week_seq AS d_week_seq, sun_sales AS sun_sales2, mon_sales AS mon_sales2, tue_sales AS tue_sales2, wed_sales AS wed_sales2, thu_sales AS thu_sales2, fri_sales AS fri_sales2, sat_sales AS sat_sales2 FROM wswscs, TPCDS_1000GB.DATE_DIM d2 WHERE d2.d_week_seq = wswscs.d_week_seq AND d2.d_year = 2001 + 1) y2
WHERE y1.d_week_seq = y2.d_week_seq - 53
ORDER BY y1.d_week_seq LIMIT 100;

-- Q3: Item Brand Sales
SELECT dt.d_year, item.i_brand_id brand_id, item.i_brand brand, SUM(ss_ext_sales_price) sum_agg
FROM TPCDS_1000GB.DATE_DIM dt, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM
WHERE dt.d_date_sk = store_sales.ss_sold_date_sk AND store_sales.ss_item_sk = item.i_item_sk AND item.i_manufact_id = 128 AND dt.d_moy = 11
GROUP BY dt.d_year, item.i_brand, item.i_brand_id
ORDER BY dt.d_year, sum_agg DESC, brand_id LIMIT 100;

-- Q4: Customer Preferred Channel
WITH year_total AS (
  SELECT c_customer_id customer_id, c_first_name customer_first_name, c_last_name customer_last_name, c_preferred_cust_flag customer_preferred_cust_flag, c_birth_country customer_birth_country, c_login customer_login, c_email_address customer_email_address, d_year dyear, SUM(((ss_ext_list_price-ss_ext_wholesale_cost-ss_ext_discount_amt)+ss_ext_sales_price)/2) year_total, 's' sale_type
  FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
  WHERE c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk
  GROUP BY c_customer_id, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_country, c_login, c_email_address, d_year
  UNION ALL
  SELECT c_customer_id customer_id, c_first_name customer_first_name, c_last_name customer_last_name, c_preferred_cust_flag customer_preferred_cust_flag, c_birth_country customer_birth_country, c_login customer_login, c_email_address customer_email_address, d_year dyear, SUM(((cs_ext_list_price-cs_ext_wholesale_cost-cs_ext_discount_amt)+cs_ext_sales_price)/2) year_total, 'c' sale_type
  FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM
  WHERE c_customer_sk = cs_bill_customer_sk AND cs_sold_date_sk = d_date_sk
  GROUP BY c_customer_id, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_country, c_login, c_email_address, d_year
  UNION ALL
  SELECT c_customer_id customer_id, c_first_name customer_first_name, c_last_name customer_last_name, c_preferred_cust_flag customer_preferred_cust_flag, c_birth_country customer_birth_country, c_login customer_login, c_email_address customer_email_address, d_year dyear, SUM(((ws_ext_list_price-ws_ext_wholesale_cost-ws_ext_discount_amt)+ws_ext_sales_price)/2) year_total, 'w' sale_type
  FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM
  WHERE c_customer_sk = ws_bill_customer_sk AND ws_sold_date_sk = d_date_sk
  GROUP BY c_customer_id, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_country, c_login, c_email_address, d_year
)
SELECT t_s_secyear.customer_id, t_s_secyear.customer_first_name, t_s_secyear.customer_last_name, t_s_secyear.customer_preferred_cust_flag
FROM year_total t_s_firstyear, year_total t_s_secyear, year_total t_c_firstyear, year_total t_c_secyear, year_total t_w_firstyear, year_total t_w_secyear
WHERE t_s_secyear.customer_id = t_s_firstyear.customer_id AND t_s_firstyear.customer_id = t_c_secyear.customer_id AND t_s_firstyear.customer_id = t_c_firstyear.customer_id AND t_s_firstyear.customer_id = t_w_firstyear.customer_id AND t_s_firstyear.customer_id = t_w_secyear.customer_id
AND t_s_firstyear.sale_type = 's' AND t_c_firstyear.sale_type = 'c' AND t_w_firstyear.sale_type = 'w' AND t_s_secyear.sale_type = 's' AND t_c_secyear.sale_type = 'c' AND t_w_secyear.sale_type = 'w'
AND t_s_firstyear.dyear = 2001 AND t_s_secyear.dyear = 2001+1 AND t_c_firstyear.dyear = 2001 AND t_c_secyear.dyear = 2001+1 AND t_w_firstyear.dyear = 2001 AND t_w_secyear.dyear = 2001+1
AND t_s_firstyear.year_total > 0 AND t_c_firstyear.year_total > 0 AND t_w_firstyear.year_total > 0
AND CASE WHEN t_c_firstyear.year_total > 0 THEN t_c_secyear.year_total / t_c_firstyear.year_total ELSE NULL END > CASE WHEN t_s_firstyear.year_total > 0 THEN t_s_secyear.year_total / t_s_firstyear.year_total ELSE NULL END
AND CASE WHEN t_c_firstyear.year_total > 0 THEN t_c_secyear.year_total / t_c_firstyear.year_total ELSE NULL END > CASE WHEN t_w_firstyear.year_total > 0 THEN t_w_secyear.year_total / t_w_firstyear.year_total ELSE NULL END
ORDER BY t_s_secyear.customer_id, t_s_secyear.customer_first_name, t_s_secyear.customer_last_name, t_s_secyear.customer_preferred_cust_flag LIMIT 100;

-- Q5: Store Web Catalog Sales by Region
WITH ssr AS (
  SELECT s_store_id, SUM(ss_ext_sales_price) AS sales, SUM(ss_net_profit) AS profit, COALESCE(SUM(sr_return_amt), 0) AS returns_amt, COALESCE(SUM(sr_net_loss), 0) AS profit_loss
  FROM TPCDS_1000GB.STORE_SALES LEFT JOIN TPCDS_1000GB.STORE_RETURNS ON ss_item_sk = sr_item_sk AND ss_ticket_number = sr_ticket_number,
    TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '14' DAY AND ss_store_sk = s_store_sk
  GROUP BY s_store_id
),
csr AS (
  SELECT cp_catalog_page_id, SUM(cs_ext_sales_price) AS sales, SUM(cs_net_profit) AS profit, COALESCE(SUM(cr_return_amount), 0) AS returns_amt, COALESCE(SUM(cr_net_loss), 0) AS profit_loss
  FROM TPCDS_1000GB.CATALOG_SALES LEFT JOIN TPCDS_1000GB.CATALOG_RETURNS ON cs_item_sk = cr_item_sk AND cs_order_number = cr_order_number,
    TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CATALOG_PAGE
  WHERE cs_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '14' DAY AND cs_catalog_page_sk = cp_catalog_page_sk
  GROUP BY cp_catalog_page_id
),
wsr AS (
  SELECT web_site_id, SUM(ws_ext_sales_price) AS sales, SUM(ws_net_profit) AS profit, COALESCE(SUM(wr_return_amt), 0) AS returns_amt, COALESCE(SUM(wr_net_loss), 0) AS profit_loss
  FROM TPCDS_1000GB.WEB_SALES LEFT JOIN TPCDS_1000GB.WEB_RETURNS ON ws_item_sk = wr_item_sk AND ws_order_number = wr_order_number,
    TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.WEB_SITE
  WHERE ws_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '14' DAY AND ws_web_site_sk = web_site_sk
  GROUP BY web_site_id
)
SELECT channel, id, SUM(sales) AS total_sales, SUM(returns_amt) AS total_returns, SUM(profit) AS total_profit
FROM (
  SELECT 'store channel' AS channel, 'store' || s_store_id AS id, sales, returns_amt, (profit - profit_loss) AS profit FROM ssr
  UNION ALL
  SELECT 'catalog channel' AS channel, 'catalog_page' || cp_catalog_page_id AS id, sales, returns_amt, (profit - profit_loss) AS profit FROM csr
  UNION ALL
  SELECT 'web channel' AS channel, 'web_site' || web_site_id AS id, sales, returns_amt, (profit - profit_loss) AS profit FROM wsr
) x
GROUP BY ROLLUP(channel, id)
ORDER BY channel, id LIMIT 100;

-- Q6: Sales Quantity Filter
SELECT a.ca_state state_code, COUNT(*) cnt
FROM TPCDS_1000GB.CUSTOMER_ADDRESS a, TPCDS_1000GB.CUSTOMER c, TPCDS_1000GB.STORE_SALES s, TPCDS_1000GB.DATE_DIM d, TPCDS_1000GB.ITEM i
WHERE a.ca_address_sk = c.c_current_addr_sk AND c.c_customer_sk = s.ss_customer_sk AND s.ss_sold_date_sk = d.d_date_sk AND s.ss_item_sk = i.i_item_sk AND d.d_month_seq = (SELECT DISTINCT d_month_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_year = 2001 AND d_moy = 1)
AND i.i_current_price > 1.2 * (SELECT AVG(j.i_current_price) FROM TPCDS_1000GB.ITEM j WHERE j.i_category = i.i_category)
GROUP BY a.ca_state
HAVING COUNT(*) >= 10
ORDER BY cnt LIMIT 100;

-- Q7: Avg Qty Price Discount by Item
SELECT i_item_id, AVG(ss_quantity) agg1, AVG(ss_list_price) agg2, AVG(ss_coupon_amt) agg3, AVG(ss_sales_price) agg4
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.ITEM, TPCDS_1000GB.PROMOTION
WHERE ss_sold_date_sk = d_date_sk AND ss_item_sk = i_item_sk AND ss_cdemo_sk = cd_demo_sk AND ss_promo_sk = p_promo_sk
AND cd_gender = 'M' AND cd_marital_status = 'S' AND cd_education_status = 'College'
AND (p_channel_email = 'N' OR p_channel_event = 'N')
AND d_year = 2000
GROUP BY i_item_id
ORDER BY i_item_id LIMIT 100;

-- Q8: Store Sales in Specific Zip
SELECT s_store_name, SUM(ss_net_profit)
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE,
  (SELECT ca_zip FROM (
    SELECT SUBSTR(ca_zip, 1, 5) ca_zip FROM TPCDS_1000GB.CUSTOMER_ADDRESS WHERE SUBSTR(ca_zip, 1, 5) IN ('24128','76232','65084','87816','83926','77556','20548','26231','43848','15126','91137','61265','98294','25782','17920','18498','28577','83583','31620','04734','22879','16455','47## ','26005','27137','73628','80348','51089','40225','72305','85816','68621','13955','36345','76576','78145','22245','73084','93818','43146','60930','01onal','78250','64460','43338','73647','35812','86057','39736','93862','35436','30676','24676','99543','28875','74503','97188','93433','39345','02568','24206','45368','10845','99063','18498','49130','29067','59844','62577','89498','93415','44709','97649','76510','07802','63581','46073','24597','67785','76450','36845','63250','58463','07552','65281','68010','50906','93740','80007','89545','36505','56438','60365','76498','68100')
    INTERSECT
    SELECT ca_zip FROM (
      SELECT SUBSTR(ca_zip, 1, 5) ca_zip, COUNT(*) cnt FROM TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.CUSTOMER
      WHERE ca_address_sk = c_current_addr_sk AND c_preferred_cust_flag = 'Y'
      GROUP BY ca_zip HAVING COUNT(*) > 10
    ) A1
  ) A2
) V1
WHERE ss_store_sk = s_store_sk AND ss_sold_date_sk = d_date_sk AND d_qoy = 2 AND d_year = 1998
AND (SUBSTR(s_zip, 1, 2) = SUBSTR(V1.ca_zip, 1, 2))
GROUP BY s_store_name
ORDER BY s_store_name LIMIT 100;

-- Q9: Reason for Excess Discount
SELECT CASE WHEN (SELECT COUNT(*) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 1 AND 20) > 74129 THEN (SELECT AVG(ss_ext_discount_amt) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 1 AND 20) ELSE (SELECT AVG(ss_net_paid) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 1 AND 20) END bucket1,
CASE WHEN (SELECT COUNT(*) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 21 AND 40) > 122840 THEN (SELECT AVG(ss_ext_discount_amt) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 21 AND 40) ELSE (SELECT AVG(ss_net_paid) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 21 AND 40) END bucket2,
CASE WHEN (SELECT COUNT(*) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 41 AND 60) > 56580 THEN (SELECT AVG(ss_ext_discount_amt) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 41 AND 60) ELSE (SELECT AVG(ss_net_paid) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 41 AND 60) END bucket3,
CASE WHEN (SELECT COUNT(*) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 61 AND 80) > 10097 THEN (SELECT AVG(ss_ext_discount_amt) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 61 AND 80) ELSE (SELECT AVG(ss_net_paid) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 61 AND 80) END bucket4,
CASE WHEN (SELECT COUNT(*) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 81 AND 100) > 165306 THEN (SELECT AVG(ss_ext_discount_amt) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 81 AND 100) ELSE (SELECT AVG(ss_net_paid) FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 81 AND 100) END bucket5
FROM TPCDS_1000GB.REASON
WHERE r_reason_sk = 1;

-- Q10: Customer Demographics by County
SELECT cd_gender, cd_marital_status, cd_education_status, COUNT(*) cnt1, cd_purchase_estimate, COUNT(*) cnt2, cd_credit_rating, COUNT(*) cnt3, cd_dep_count, COUNT(*) cnt4, cd_dep_employed_count, COUNT(*) cnt5, cd_dep_college_count, COUNT(*) cnt6
FROM TPCDS_1000GB.CUSTOMER c, TPCDS_1000GB.CUSTOMER_ADDRESS ca, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS
WHERE c.c_current_addr_sk = ca.ca_address_sk AND ca_county IN ('Rush County', 'Toole County', 'Jefferson County', 'Dona Ana County', 'La Porte County')
AND cd_demo_sk = c.c_current_cdemo_sk
AND EXISTS (SELECT * FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2002 AND d_moy BETWEEN 1 AND 1+3)
AND (EXISTS (SELECT * FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = ws_bill_customer_sk AND ws_sold_date_sk = d_date_sk AND d_year = 2002 AND d_moy BETWEEN 1 AND 1+3)
  OR EXISTS (SELECT * FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = cs_ship_customer_sk AND cs_sold_date_sk = d_date_sk AND d_year = 2002 AND d_moy BETWEEN 1 AND 1+3))
GROUP BY cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, cd_credit_rating, cd_dep_count, cd_dep_employed_count, cd_dep_college_count
ORDER BY cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, cd_credit_rating, cd_dep_count, cd_dep_employed_count, cd_dep_college_count
LIMIT 100;

-- Q11: Customer Annual Balance
WITH year_total AS (
  SELECT c_customer_id customer_id, c_first_name customer_first_name, c_last_name customer_last_name, c_preferred_cust_flag customer_preferred_cust_flag, c_birth_country customer_birth_country, c_login customer_login, c_email_address customer_email_address, d_year dyear, SUM(ss_ext_list_price-ss_ext_discount_amt) year_total, 's' sale_type
  FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
  WHERE c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk
  GROUP BY c_customer_id, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_country, c_login, c_email_address, d_year
  UNION ALL
  SELECT c_customer_id customer_id, c_first_name customer_first_name, c_last_name customer_last_name, c_preferred_cust_flag customer_preferred_cust_flag, c_birth_country customer_birth_country, c_login customer_login, c_email_address customer_email_address, d_year dyear, SUM(ws_ext_list_price-ws_ext_discount_amt) year_total, 'w' sale_type
  FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM
  WHERE c_customer_sk = ws_bill_customer_sk AND ws_sold_date_sk = d_date_sk
  GROUP BY c_customer_id, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_country, c_login, c_email_address, d_year
)
SELECT t_s_secyear.customer_id, t_s_secyear.customer_first_name, t_s_secyear.customer_last_name, t_s_secyear.customer_preferred_cust_flag
FROM year_total t_s_firstyear, year_total t_s_secyear, year_total t_w_firstyear, year_total t_w_secyear
WHERE t_s_secyear.customer_id = t_s_firstyear.customer_id AND t_s_firstyear.customer_id = t_w_secyear.customer_id AND t_s_firstyear.customer_id = t_w_firstyear.customer_id
AND t_s_firstyear.sale_type = 's' AND t_w_firstyear.sale_type = 'w' AND t_s_secyear.sale_type = 's' AND t_w_secyear.sale_type = 'w'
AND t_s_firstyear.dyear = 2001 AND t_s_secyear.dyear = 2001+1 AND t_w_firstyear.dyear = 2001 AND t_w_secyear.dyear = 2001+1
AND t_s_firstyear.year_total > 0 AND t_w_firstyear.year_total > 0
AND CASE WHEN t_w_firstyear.year_total > 0 THEN t_w_secyear.year_total / t_w_firstyear.year_total ELSE NULL END > CASE WHEN t_s_firstyear.year_total > 0 THEN t_s_secyear.year_total / t_s_firstyear.year_total ELSE NULL END
ORDER BY t_s_secyear.customer_id, t_s_secyear.customer_first_name, t_s_secyear.customer_last_name, t_s_secyear.customer_preferred_cust_flag
LIMIT 100;

-- Q12: Web Item Revenue
SELECT i_item_id, i_item_desc, i_category, i_class, i_current_price,
  SUM(ws_ext_sales_price) AS itemrevenue,
  SUM(ws_ext_sales_price)*100/SUM(SUM(ws_ext_sales_price)) OVER (PARTITION BY i_class) AS revenueratio
FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
WHERE ws_item_sk = i_item_sk AND i_category IN ('Sports', 'Books', 'Home')
AND ws_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '1999-02-22' AND DATE '1999-02-22' + INTERVAL '30' DAY
GROUP BY i_item_id, i_item_desc, i_category, i_class, i_current_price
ORDER BY i_category, i_class, i_item_id, i_item_desc, revenueratio LIMIT 100;

-- Q13: Store Sales Demographics
SELECT AVG(ss_quantity) avg_qty, AVG(ss_ext_sales_price) avg_price, AVG(ss_ext_wholesale_cost) avg_wholesale, SUM(ss_ext_wholesale_cost) total_wholesale
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.DATE_DIM
WHERE s_store_sk = ss_store_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2001
AND ((ss_cdemo_sk = cd_demo_sk AND cd_marital_status = 'M' AND cd_education_status = 'Advanced Degree' AND ss_sales_price BETWEEN 100.00 AND 150.00 AND hd_dep_count = 3)
  OR (ss_cdemo_sk = cd_demo_sk AND cd_marital_status = 'S' AND cd_education_status = 'College' AND ss_sales_price BETWEEN 50.00 AND 100.00 AND hd_dep_count = 1)
  OR (ss_cdemo_sk = cd_demo_sk AND cd_marital_status = 'W' AND cd_education_status = '2 yr Degree' AND ss_sales_price BETWEEN 150.00 AND 200.00 AND hd_dep_count = 1))
AND ((ss_addr_sk = ca_address_sk AND ca_country = 'United States' AND ca_state IN ('TX', 'OH', 'TX') AND ss_net_profit BETWEEN 100 AND 200)
  OR (ss_addr_sk = ca_address_sk AND ca_country = 'United States' AND ca_state IN ('OR', 'NM', 'KY') AND ss_net_profit BETWEEN 150 AND 300)
  OR (ss_addr_sk = ca_address_sk AND ca_country = 'United States' AND ca_state IN ('VA', 'TX', 'MS') AND ss_net_profit BETWEEN 50 AND 250))
AND ss_hdemo_sk = hd_demo_sk;

-- Q14: Cross Channel Sales
WITH cross_items AS (
  SELECT i_item_sk ss_item_sk FROM TPCDS_1000GB.ITEM,
    (SELECT iss.i_brand_id brand_id, iss.i_class_id class_id, iss.i_category_id category_id
     FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM iss, TPCDS_1000GB.DATE_DIM d1
     WHERE ss_item_sk = iss.i_item_sk AND ss_sold_date_sk = d1.d_date_sk AND d1.d_year BETWEEN 1999 AND 1999+2
     INTERSECT
     SELECT ics.i_brand_id, ics.i_class_id, ics.i_category_id
     FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.ITEM ics, TPCDS_1000GB.DATE_DIM d2
     WHERE cs_item_sk = ics.i_item_sk AND cs_sold_date_sk = d2.d_date_sk AND d2.d_year BETWEEN 1999 AND 1999+2
     INTERSECT
     SELECT iws.i_brand_id, iws.i_class_id, iws.i_category_id
     FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.ITEM iws, TPCDS_1000GB.DATE_DIM d3
     WHERE ws_item_sk = iws.i_item_sk AND ws_sold_date_sk = d3.d_date_sk AND d3.d_year BETWEEN 1999 AND 1999+2) x
  WHERE i_brand_id = brand_id AND i_class_id = class_id AND i_category_id = category_id
),
avg_sales AS (
  SELECT AVG(quantity*list_price) average_sales FROM (
    SELECT ss_quantity quantity, ss_list_price list_price FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM WHERE ss_sold_date_sk = d_date_sk AND d_year BETWEEN 1999 AND 1999+2
    UNION ALL
    SELECT cs_quantity quantity, cs_list_price list_price FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM WHERE cs_sold_date_sk = d_date_sk AND d_year BETWEEN 1999 AND 1999+2
    UNION ALL
    SELECT ws_quantity quantity, ws_list_price list_price FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM WHERE ws_sold_date_sk = d_date_sk AND d_year BETWEEN 1999 AND 1999+2
  ) t
)
SELECT * FROM
(SELECT 'store' channel, i_brand_id, i_class_id, i_category_id,
  SUM(ss_quantity*ss_list_price) sales, COUNT(*) number_sales
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE ss_item_sk IN (SELECT ss_item_sk FROM cross_items) AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk
  AND d_week_seq = (SELECT d_week_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_year = 1999+1 AND d_moy = 12 AND d_dom = 1)
  GROUP BY i_brand_id, i_class_id, i_category_id
  HAVING SUM(ss_quantity*ss_list_price) > (SELECT average_sales FROM avg_sales)) this_year,
(SELECT 'store' channel, i_brand_id, i_class_id, i_category_id,
  SUM(ss_quantity*ss_list_price) sales, COUNT(*) number_sales
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE ss_item_sk IN (SELECT ss_item_sk FROM cross_items) AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk
  AND d_week_seq = (SELECT d_week_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_year = 1999 AND d_moy = 12 AND d_dom = 1)
  GROUP BY i_brand_id, i_class_id, i_category_id
  HAVING SUM(ss_quantity*ss_list_price) > (SELECT average_sales FROM avg_sales)) last_year
WHERE this_year.i_brand_id = last_year.i_brand_id
  AND this_year.i_class_id = last_year.i_class_id
  AND this_year.i_category_id = last_year.i_category_id
ORDER BY this_year.channel, this_year.i_brand_id, this_year.i_class_id, this_year.i_category_id LIMIT 100;

-- Q15: Catalog Sales by Zip
SELECT ca_zip, SUM(cs_sales_price)
FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.DATE_DIM
WHERE cs_bill_customer_sk = c_customer_sk AND c_current_addr_sk = ca_address_sk
AND (SUBSTR(ca_zip, 1, 5) IN ('85669', '86197', '88274', '83405', '86475', '85392', '85460', '80348', '81792')
  OR ca_state IN ('CA', 'WA', 'GA') OR cs_sales_price > 500)
AND cs_sold_date_sk = d_date_sk AND d_qoy = 2 AND d_year = 2001
GROUP BY ca_zip
ORDER BY ca_zip LIMIT 100;

-- Q16: Catalog Sales Duplicate Orders
SELECT COUNT(DISTINCT cs_order_number) AS order_count, SUM(cs_ext_ship_cost) AS total_shipping_cost, SUM(cs_net_profit) AS total_net_profit
FROM TPCDS_1000GB.CATALOG_SALES cs1, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.CALL_CENTER
WHERE d_date BETWEEN DATE '2002-02-01' AND DATE '2002-02-01' + INTERVAL '60' DAY
AND cs1.cs_ship_date_sk = d_date_sk AND cs1.cs_ship_addr_sk = ca_address_sk AND ca_state = 'GA'
AND cs1.cs_call_center_sk = cc_call_center_sk AND cc_county IN ('Williamson County', 'Ziebach County', 'Walker County', 'Fairfield County', 'Richland County')
AND EXISTS (SELECT * FROM TPCDS_1000GB.CATALOG_SALES cs2 WHERE cs1.cs_order_number = cs2.cs_order_number AND cs1.cs_warehouse_sk <> cs2.cs_warehouse_sk)
AND NOT EXISTS (SELECT * FROM TPCDS_1000GB.CATALOG_RETURNS cr1 WHERE cs1.cs_order_number = cr1.cr_order_number)
ORDER BY order_count LIMIT 100;

-- Q17: Store Catalog Returns Analysis
SELECT i_item_id, i_item_desc, s_state,
  COUNT(ss_quantity) AS store_sales_quantitycount, AVG(ss_quantity) AS store_sales_quantityave, STDDEV_SAMP(ss_quantity) AS store_sales_quantitystdev, STDDEV_SAMP(ss_quantity)/AVG(ss_quantity) AS store_sales_quantitycov,
  COUNT(sr_return_quantity) AS store_returns_quantitycount, AVG(sr_return_quantity) AS store_returns_quantityave, STDDEV_SAMP(sr_return_quantity) AS store_returns_quantitystdev, STDDEV_SAMP(sr_return_quantity)/AVG(sr_return_quantity) AS store_returns_quantitycov,
  COUNT(cs_quantity) AS catalog_sales_quantitycount, AVG(cs_quantity) AS catalog_sales_quantityave, STDDEV_SAMP(cs_quantity) AS catalog_sales_quantitystdev, STDDEV_SAMP(cs_quantity)/AVG(cs_quantity) AS catalog_sales_quantitycov
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.DATE_DIM d2, TPCDS_1000GB.DATE_DIM d3, TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM
WHERE d1.d_quarter_name = '2001Q1' AND d1.d_date_sk = ss_sold_date_sk AND i_item_sk = ss_item_sk AND s_store_sk = ss_store_sk AND ss_customer_sk = sr_customer_sk AND ss_item_sk = sr_item_sk AND ss_ticket_number = sr_ticket_number AND sr_returned_date_sk = d2.d_date_sk AND d2.d_quarter_name IN ('2001Q1', '2001Q2', '2001Q3') AND sr_customer_sk = cs_bill_customer_sk AND sr_item_sk = cs_item_sk AND cs_sold_date_sk = d3.d_date_sk AND d3.d_quarter_name IN ('2001Q1', '2001Q2', '2001Q3') AND s_state IN ('SD', 'OH', 'MI', 'LA', 'MO', 'NM')
GROUP BY i_item_id, i_item_desc, s_state
ORDER BY i_item_id, i_item_desc, s_state LIMIT 100;

-- Q18: Catalog Sales Demographics
SELECT i_item_id, ca_country, ca_state, ca_county,
  AVG(CAST(cs_quantity AS DECIMAL(12,2))) agg1, AVG(CAST(cs_list_price AS DECIMAL(12,2))) agg2,
  AVG(CAST(cs_coupon_amt AS DECIMAL(12,2))) agg3, AVG(CAST(cs_sales_price AS DECIMAL(12,2))) agg4,
  AVG(CAST(cs_net_profit AS DECIMAL(12,2))) agg5, AVG(CAST(c_birth_year AS DECIMAL(12,2))) agg6,
  AVG(CAST(cd_dep_count AS DECIMAL(12,2))) agg7
FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.ITEM
WHERE cs_sold_date_sk = d_date_sk AND cs_item_sk = i_item_sk AND cs_bill_cdemo_sk = cd_demo_sk AND cs_bill_customer_sk = c_customer_sk AND cd_gender = 'F' AND cd_education_status = 'Unknown' AND c_current_cdemo_sk = cd_demo_sk AND c_current_addr_sk = ca_address_sk AND c_birth_month IN (1, 6, 8, 9, 12, 2) AND d_year = 1998 AND ca_state IN ('MS', 'IN', 'ND', 'OK', 'NM', 'VA', 'MS')
GROUP BY ROLLUP(i_item_id, ca_country, ca_state, ca_county)
ORDER BY ca_country, ca_state, ca_county, i_item_id LIMIT 100;

-- Q19: Store Sales by Item Manager
SELECT i_brand_id brand_id, i_brand brand, i_manufact_id, i_manufact, SUM(ss_ext_sales_price) ext_price
FROM TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.STORE
WHERE d_date_sk = ss_sold_date_sk AND ss_item_sk = i_item_sk AND i_manager_id = 8 AND d_moy = 11 AND d_year = 1998
AND ss_customer_sk = c_customer_sk AND c_current_addr_sk = ca_address_sk AND SUBSTR(ca_zip, 1, 5) <> SUBSTR(s_zip, 1, 5) AND ss_store_sk = s_store_sk
GROUP BY i_brand, i_brand_id, i_manufact_id, i_manufact
ORDER BY ext_price DESC, i_brand, i_brand_id, i_manufact_id, i_manufact LIMIT 100;

-- Q20: Catalog Sales by Item Date
SELECT i_item_id, i_item_desc, i_category, i_class, i_current_price,
  SUM(cs_ext_sales_price) AS itemrevenue,
  SUM(cs_ext_sales_price)*100/SUM(SUM(cs_ext_sales_price)) OVER (PARTITION BY i_class) AS revenueratio
FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
WHERE cs_item_sk = i_item_sk AND i_category IN ('Sports', 'Books', 'Home')
AND cs_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '1999-02-22' AND DATE '1999-02-22' + INTERVAL '30' DAY
GROUP BY i_item_id, i_item_desc, i_category, i_class, i_current_price
ORDER BY i_category, i_class, i_item_id, i_item_desc, revenueratio LIMIT 100;

-- Q21: Inventory Analysis
SELECT * FROM (
  SELECT w_warehouse_name, i_item_id,
    SUM(CASE WHEN d_date < DATE '2000-03-11' THEN inv_quantity_on_hand ELSE 0 END) AS inv_before,
    SUM(CASE WHEN d_date >= DATE '2000-03-11' THEN inv_quantity_on_hand ELSE 0 END) AS inv_after
  FROM TPCDS_1000GB.INVENTORY, TPCDS_1000GB.WAREHOUSE, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE i_current_price BETWEEN 0.99 AND 1.49 AND i_item_sk = inv_item_sk AND inv_warehouse_sk = w_warehouse_sk AND inv_date_sk = d_date_sk
  AND d_date BETWEEN DATE '2000-03-11' - INTERVAL '30' DAY AND DATE '2000-03-11' + INTERVAL '30' DAY
  GROUP BY w_warehouse_name, i_item_id
) x
WHERE (CASE WHEN inv_before > 0 THEN inv_after / inv_before ELSE NULL END) BETWEEN 2.0/3.0 AND 3.0/2.0
ORDER BY w_warehouse_name, i_item_id LIMIT 100;

-- Q22: Inventory Quantity Bands
SELECT i_product_name, i_brand, i_class, i_category,
  AVG(inv_quantity_on_hand) qoh
FROM TPCDS_1000GB.INVENTORY, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.ITEM, TPCDS_1000GB.WAREHOUSE
WHERE inv_date_sk = d_date_sk AND inv_item_sk = i_item_sk AND inv_warehouse_sk = w_warehouse_sk AND d_month_seq BETWEEN 1200 AND 1200+11
GROUP BY ROLLUP(i_product_name, i_brand, i_class, i_category)
ORDER BY qoh, i_product_name, i_brand, i_class, i_category LIMIT 100;

-- Q23: Frequent Store Sales Customer
WITH frequent_ss_items AS (
  SELECT SUBSTR(i_item_desc, 1, 30) itemdesc, i_item_sk item_sk, d_date solddate, COUNT(*) cnt
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.ITEM
  WHERE ss_sold_date_sk = d_date_sk AND ss_item_sk = i_item_sk AND d_year IN (2000, 2000+1, 2000+2, 2000+3)
  GROUP BY SUBSTR(i_item_desc, 1, 30), i_item_sk, d_date
  HAVING COUNT(*) > 4
),
max_store_sales AS (
  SELECT MAX(csales) tpcds_cmax FROM (
    SELECT c_customer_sk, SUM(ss_quantity*ss_sales_price) csales
    FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
    WHERE c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk AND d_year IN (2000, 2000+1, 2000+2, 2000+3)
    GROUP BY c_customer_sk
  ) t
),
best_ss_customer AS (
  SELECT c_customer_sk, SUM(ss_quantity*ss_sales_price) ssales
  FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.STORE_SALES
  WHERE c_customer_sk = ss_customer_sk
  GROUP BY c_customer_sk
  HAVING SUM(ss_quantity*ss_sales_price) > (95.0/100.0) * (SELECT * FROM max_store_sales)
)
SELECT SUM(sales) total_sales FROM (
  SELECT cs_quantity*cs_list_price sales
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM
  WHERE d_year = 2000 AND d_moy = 2 AND cs_sold_date_sk = d_date_sk
  AND cs_item_sk IN (SELECT item_sk FROM frequent_ss_items)
  AND cs_bill_customer_sk IN (SELECT c_customer_sk FROM best_ss_customer)
  UNION ALL
  SELECT ws_quantity*ws_list_price sales
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM
  WHERE d_year = 2000 AND d_moy = 2 AND ws_sold_date_sk = d_date_sk
  AND ws_item_sk IN (SELECT item_sk FROM frequent_ss_items)
  AND ws_bill_customer_sk IN (SELECT c_customer_sk FROM best_ss_customer)
) t LIMIT 100;

-- Q24: Store Sales by Color Market
WITH ssales AS (
  SELECT c_last_name, c_first_name, s_store_name, ca_state, s_state, i_color, i_current_price, i_manager_id, i_units, i_size,
    SUM(ss_net_paid) netpaid
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS
  WHERE ss_ticket_number = sr_ticket_number AND ss_item_sk = sr_item_sk AND ss_customer_sk = c_customer_sk AND ss_item_sk = i_item_sk AND ss_store_sk = s_store_sk AND c_current_addr_sk = ca_address_sk
  AND c_birth_country <> UPPER(ca_country) AND s_zip = ca_zip AND s_market_id = 8
  GROUP BY c_last_name, c_first_name, s_store_name, ca_state, s_state, i_color, i_current_price, i_manager_id, i_units, i_size
)
SELECT c_last_name, c_first_name, s_store_name, SUM(netpaid) paid
FROM ssales
WHERE i_color = 'almond'
GROUP BY c_last_name, c_first_name, s_store_name
HAVING SUM(netpaid) > (SELECT 0.05 * AVG(netpaid) FROM ssales)
ORDER BY c_last_name, c_first_name, s_store_name;

-- Q25: Multi-Channel Returns
SELECT i_item_id, i_item_desc, s_store_id, s_store_name,
  SUM(ss_net_profit) AS store_sales_profit, SUM(sr_net_loss) AS store_returns_loss, SUM(cs_net_profit) AS catalog_sales_profit
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.DATE_DIM d2, TPCDS_1000GB.DATE_DIM d3, TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM
WHERE d1.d_moy = 4 AND d1.d_year = 2001 AND d1.d_date_sk = ss_sold_date_sk AND i_item_sk = ss_item_sk AND s_store_sk = ss_store_sk
AND ss_customer_sk = sr_customer_sk AND ss_item_sk = sr_item_sk AND ss_ticket_number = sr_ticket_number
AND sr_returned_date_sk = d2.d_date_sk AND d2.d_moy BETWEEN 4 AND 10 AND d2.d_year = 2001
AND sr_customer_sk = cs_bill_customer_sk AND sr_item_sk = cs_item_sk
AND cs_sold_date_sk = d3.d_date_sk AND d3.d_moy BETWEEN 4 AND 10 AND d3.d_year = 2001
GROUP BY i_item_id, i_item_desc, s_store_id, s_store_name
ORDER BY i_item_id, i_item_desc, s_store_id, s_store_name LIMIT 100;

-- Q26: Catalog Sales Promo Analysis
SELECT i_item_id, AVG(cs_quantity) agg1, AVG(cs_list_price) agg2, AVG(cs_coupon_amt) agg3, AVG(cs_sales_price) agg4
FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.ITEM, TPCDS_1000GB.PROMOTION
WHERE cs_sold_date_sk = d_date_sk AND cs_item_sk = i_item_sk AND cs_bill_cdemo_sk = cd_demo_sk AND cs_promo_sk = p_promo_sk
AND cd_gender = 'M' AND cd_marital_status = 'S' AND cd_education_status = 'College'
AND d_year = 2000 AND (p_channel_email = 'N' OR p_channel_event = 'N')
GROUP BY i_item_id
ORDER BY i_item_id LIMIT 100;

-- Q27: Store Sales by State Item
SELECT i_item_id, s_state,
  GROUPING(s_state) g_state,
  AVG(ss_quantity) agg1, AVG(ss_list_price) agg2, AVG(ss_coupon_amt) agg3, AVG(ss_sales_price) agg4
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM
WHERE ss_sold_date_sk = d_date_sk AND ss_item_sk = i_item_sk AND ss_store_sk = s_store_sk AND ss_cdemo_sk = cd_demo_sk
AND cd_gender = 'M' AND cd_marital_status = 'S' AND cd_education_status = 'College'
AND d_year = 2002 AND s_state IN ('TN', 'SD', 'AL', 'SC', 'OH', 'LA')
GROUP BY ROLLUP(i_item_id, s_state)
ORDER BY i_item_id, s_state LIMIT 100;

-- Q28: Avg Sales Quantity Analysis
SELECT * FROM (
  SELECT AVG(ss_list_price) B1_LP, COUNT(ss_list_price) B1_CNT, COUNT(DISTINCT ss_list_price) B1_CNTD
  FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 0 AND 5
  AND (ss_list_price BETWEEN 8 AND 8+10 OR ss_coupon_amt BETWEEN 459 AND 459+1000 OR ss_wholesale_cost BETWEEN 57 AND 57+20)
) B1,
(SELECT AVG(ss_list_price) B2_LP, COUNT(ss_list_price) B2_CNT, COUNT(DISTINCT ss_list_price) B2_CNTD
  FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 6 AND 10
  AND (ss_list_price BETWEEN 90 AND 90+10 OR ss_coupon_amt BETWEEN 2323 AND 2323+1000 OR ss_wholesale_cost BETWEEN 31 AND 31+20)
) B2,
(SELECT AVG(ss_list_price) B3_LP, COUNT(ss_list_price) B3_CNT, COUNT(DISTINCT ss_list_price) B3_CNTD
  FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 11 AND 15
  AND (ss_list_price BETWEEN 142 AND 142+10 OR ss_coupon_amt BETWEEN 12214 AND 12214+1000 OR ss_wholesale_cost BETWEEN 79 AND 79+20)
) B3,
(SELECT AVG(ss_list_price) B4_LP, COUNT(ss_list_price) B4_CNT, COUNT(DISTINCT ss_list_price) B4_CNTD
  FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 16 AND 20
  AND (ss_list_price BETWEEN 135 AND 135+10 OR ss_coupon_amt BETWEEN 6071 AND 6071+1000 OR ss_wholesale_cost BETWEEN 38 AND 38+20)
) B4,
(SELECT AVG(ss_list_price) B5_LP, COUNT(ss_list_price) B5_CNT, COUNT(DISTINCT ss_list_price) B5_CNTD
  FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 21 AND 25
  AND (ss_list_price BETWEEN 122 AND 122+10 OR ss_coupon_amt BETWEEN 836 AND 836+1000 OR ss_wholesale_cost BETWEEN 17 AND 17+20)
) B5,
(SELECT AVG(ss_list_price) B6_LP, COUNT(ss_list_price) B6_CNT, COUNT(DISTINCT ss_list_price) B6_CNTD
  FROM TPCDS_1000GB.STORE_SALES WHERE ss_quantity BETWEEN 26 AND 30
  AND (ss_list_price BETWEEN 154 AND 154+10 OR ss_coupon_amt BETWEEN 7326 AND 7326+1000 OR ss_wholesale_cost BETWEEN 7 AND 7+20)
) B6
LIMIT 100;

-- Q29: Multi-Channel Returns Qty
SELECT i_item_id, i_item_desc, s_store_id, s_store_name,
  AVG(ss_quantity) AS store_sales_quantity, AVG(sr_return_quantity) AS store_returns_quantity, AVG(cs_quantity) AS catalog_sales_quantity
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.DATE_DIM d2, TPCDS_1000GB.DATE_DIM d3, TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM
WHERE d1.d_moy = 9 AND d1.d_year = 1999 AND d1.d_date_sk = ss_sold_date_sk AND i_item_sk = ss_item_sk AND s_store_sk = ss_store_sk
AND ss_customer_sk = sr_customer_sk AND ss_item_sk = sr_item_sk AND ss_ticket_number = sr_ticket_number
AND sr_returned_date_sk = d2.d_date_sk AND d2.d_moy BETWEEN 9 AND 9+3 AND d2.d_year = 1999
AND sr_customer_sk = cs_bill_customer_sk AND sr_item_sk = cs_item_sk
AND cs_sold_date_sk = d3.d_date_sk AND d3.d_year IN (1999, 1999+1, 1999+2)
GROUP BY i_item_id, i_item_desc, s_store_id, s_store_name
ORDER BY i_item_id, i_item_desc, s_store_id, s_store_name LIMIT 100;

-- Q30: Web Returns by State
WITH customer_total_return AS (
  SELECT wr_returning_customer_sk AS ctr_customer_sk, ca_state AS ctr_state, SUM(wr_return_amt) AS ctr_total_return
  FROM TPCDS_1000GB.WEB_RETURNS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS
  WHERE wr_returned_date_sk = d_date_sk AND d_year = 2002 AND wr_returning_addr_sk = ca_address_sk
  GROUP BY wr_returning_customer_sk, ca_state
)
SELECT c_customer_id, c_salutation, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_day, c_birth_month, c_birth_year, c_birth_country, c_login, c_email_address, c_last_review_date_sk, ctr_total_return
FROM customer_total_return ctr1, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.CUSTOMER
WHERE ctr1.ctr_total_return > (SELECT AVG(ctr_total_return) * 1.2 FROM customer_total_return ctr2 WHERE ctr1.ctr_state = ctr2.ctr_state)
AND ca_address_sk = c_current_addr_sk AND ca_state = 'GA' AND ctr1.ctr_customer_sk = c_customer_sk
ORDER BY c_customer_id, c_salutation, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_day, c_birth_month, c_birth_year, c_birth_country, c_login, c_email_address, c_last_review_date_sk, ctr_total_return
LIMIT 100;

-- Q31: Store Web Sales by County
WITH ss AS (
  SELECT ca_county, d_qoy, d_year, SUM(ss_ext_sales_price) AS store_sales
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS
  WHERE ss_sold_date_sk = d_date_sk AND ss_addr_sk = ca_address_sk
  GROUP BY ca_county, d_qoy, d_year
),
ws AS (
  SELECT ca_county, d_qoy, d_year, SUM(ws_ext_sales_price) AS web_sales
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS
  WHERE ws_sold_date_sk = d_date_sk AND ws_bill_addr_sk = ca_address_sk
  GROUP BY ca_county, d_qoy, d_year
)
SELECT ss1.ca_county, ss1.d_year,
  ws2.web_sales / ws1.web_sales web_q1_q2_increase, ss2.store_sales / ss1.store_sales store_q1_q2_increase,
  ws3.web_sales / ws2.web_sales web_q2_q3_increase, ss3.store_sales / ss2.store_sales store_q2_q3_increase
FROM ss ss1, ss ss2, ss ss3, ws ws1, ws ws2, ws ws3
WHERE ss1.d_qoy = 1 AND ss1.d_year = 2000 AND ss2.d_qoy = 2 AND ss2.d_year = 2000 AND ss3.d_qoy = 3 AND ss3.d_year = 2000
AND ss1.ca_county = ss2.ca_county AND ss2.ca_county = ss3.ca_county
AND ws1.d_qoy = 1 AND ws1.d_year = 2000 AND ws2.d_qoy = 2 AND ws2.d_year = 2000 AND ws3.d_qoy = 3 AND ws3.d_year = 2000
AND ws1.ca_county = ss1.ca_county AND ws2.ca_county = ss2.ca_county AND ws3.ca_county = ss3.ca_county
AND CASE WHEN ws1.web_sales > 0 THEN ws2.web_sales / ws1.web_sales ELSE NULL END > CASE WHEN ss1.store_sales > 0 THEN ss2.store_sales / ss1.store_sales ELSE NULL END
AND CASE WHEN ws2.web_sales > 0 THEN ws3.web_sales / ws2.web_sales ELSE NULL END > CASE WHEN ss2.store_sales > 0 THEN ss3.store_sales / ss2.store_sales ELSE NULL END
ORDER BY ss1.ca_county;

-- Q32: Catalog Excess Discount
SELECT SUM(cs_ext_discount_amt) AS excess_discount_amount
FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
WHERE i_manufact_id = 977 AND i_item_sk = cs_item_sk
AND d_date BETWEEN DATE '2000-01-27' AND DATE '2000-01-27' + INTERVAL '90' DAY AND d_date_sk = cs_sold_date_sk
AND cs_ext_discount_amt > (
  SELECT 1.3 * AVG(cs_ext_discount_amt) FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM
  WHERE cs_item_sk = i_item_sk AND d_date BETWEEN DATE '2000-01-27' AND DATE '2000-01-27' + INTERVAL '90' DAY AND d_date_sk = cs_sold_date_sk
)
LIMIT 100;

-- Q33: Manufacturer Sales Channel
SELECT i_manufact_id, SUM(total_sales) total_sales FROM (
  SELECT i_manufact_id, SUM(ss_ext_sales_price) total_sales
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_manufact_id IN (SELECT i_manufact_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Electronics'))
  AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 5
  AND ss_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_manufact_id
  UNION ALL
  SELECT i_manufact_id, SUM(cs_ext_sales_price) total_sales
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_manufact_id IN (SELECT i_manufact_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Electronics'))
  AND cs_item_sk = i_item_sk AND cs_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 5
  AND cs_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_manufact_id
  UNION ALL
  SELECT i_manufact_id, SUM(ws_ext_sales_price) total_sales
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_manufact_id IN (SELECT i_manufact_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Electronics'))
  AND ws_item_sk = i_item_sk AND ws_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 5
  AND ws_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_manufact_id
) tmp1
GROUP BY i_manufact_id
ORDER BY total_sales LIMIT 100;

-- Q34: Store Sales Customer Detail
SELECT c_last_name, c_first_name, c_salutation, c_preferred_cust_flag, ss_ticket_number, cnt
FROM (
  SELECT ss_ticket_number, ss_customer_sk, COUNT(*) cnt
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS
  WHERE store_sales.ss_sold_date_sk = date_dim.d_date_sk AND store_sales.ss_store_sk = store.s_store_sk AND store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
  AND (date_dim.d_dom BETWEEN 1 AND 3 OR date_dim.d_dom BETWEEN 25 AND 28)
  AND (household_demographics.hd_buy_potential = '>10000' OR household_demographics.hd_buy_potential = 'Unknown')
  AND household_demographics.hd_vehicle_count > 0
  AND (CASE WHEN household_demographics.hd_vehicle_count > 0 THEN household_demographics.hd_dep_count / household_demographics.hd_vehicle_count ELSE NULL END) > 1.2
  AND date_dim.d_year IN (1999, 1999+1, 1999+2)
  AND store.s_county IN ('Williamson County', 'Ziebach County', 'Walker County', 'Fairfield County', 'Richland County', 'Franklin Parish', 'Daviess County', 'Barrow County')
  GROUP BY ss_ticket_number, ss_customer_sk
) dn, TPCDS_1000GB.CUSTOMER
WHERE ss_customer_sk = c_customer_sk AND cnt BETWEEN 15 AND 20
ORDER BY c_last_name, c_first_name, c_salutation, c_preferred_cust_flag DESC, ss_ticket_number;

-- Q35: Customer Demographics Join
SELECT ca_state, cd_gender, cd_marital_status, cd_dep_count, COUNT(*) cnt1, AVG(cd_dep_count) avg1, MAX(cd_dep_count) max1, SUM(cd_dep_count) sum1,
  cd_dep_employed_count, COUNT(*) cnt2, AVG(cd_dep_employed_count) avg2, MAX(cd_dep_employed_count) max2, SUM(cd_dep_employed_count) sum2,
  cd_dep_college_count, COUNT(*) cnt3, AVG(cd_dep_college_count) avg3, MAX(cd_dep_college_count) max3, SUM(cd_dep_college_count) sum3
FROM TPCDS_1000GB.CUSTOMER c, TPCDS_1000GB.CUSTOMER_ADDRESS ca, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS
WHERE c.c_current_addr_sk = ca.ca_address_sk AND cd_demo_sk = c.c_current_cdemo_sk
AND EXISTS (SELECT * FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2002 AND d_qoy < 4)
AND (EXISTS (SELECT * FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = ws_bill_customer_sk AND ws_sold_date_sk = d_date_sk AND d_year = 2002 AND d_qoy < 4)
  OR EXISTS (SELECT * FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = cs_ship_customer_sk AND cs_sold_date_sk = d_date_sk AND d_year = 2002 AND d_qoy < 4))
GROUP BY ca_state, cd_gender, cd_marital_status, cd_dep_count, cd_dep_employed_count, cd_dep_college_count
ORDER BY ca_state, cd_gender, cd_marital_status, cd_dep_count, cd_dep_employed_count, cd_dep_college_count
LIMIT 100;

-- Q36: Store Sales by Hierarchy
SELECT SUM(ss_net_profit)/SUM(ss_ext_sales_price) AS gross_margin, i_category, i_class,
  GROUPING(i_category)+GROUPING(i_class) AS lochierarchy,
  RANK() OVER (PARTITION BY GROUPING(i_category)+GROUPING(i_class), CASE WHEN GROUPING(i_class) = 0 THEN i_category END ORDER BY SUM(ss_net_profit)/SUM(ss_ext_sales_price) ASC) AS rank_within_parent
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.ITEM, TPCDS_1000GB.STORE
WHERE d1.d_year = 2001 AND d1.d_date_sk = ss_sold_date_sk AND i_item_sk = ss_item_sk AND s_store_sk = ss_store_sk AND s_state IN ('TN', 'SD', 'AL', 'SC', 'OH', 'LA', 'MO', 'GA')
GROUP BY ROLLUP(i_category, i_class)
ORDER BY lochierarchy DESC, CASE WHEN lochierarchy = 0 THEN i_category END, rank_within_parent LIMIT 100;

-- Q37: Catalog Item Inventory
SELECT i_item_id, i_item_desc, i_current_price
FROM TPCDS_1000GB.ITEM, TPCDS_1000GB.INVENTORY, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CATALOG_SALES
WHERE i_current_price BETWEEN 68 AND 68+30 AND inv_item_sk = i_item_sk AND d_date_sk = inv_date_sk
AND d_date BETWEEN DATE '2000-02-01' AND DATE '2000-02-01' + INTERVAL '60' DAY AND i_manufact_id IN (677, 940, 694, 808)
AND inv_quantity_on_hand BETWEEN 100 AND 500 AND cs_item_sk = i_item_sk
GROUP BY i_item_id, i_item_desc, i_current_price
ORDER BY i_item_id LIMIT 100;

-- Q38: Customer Cross Channel
SELECT COUNT(*) FROM (
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER
  WHERE store_sales.ss_sold_date_sk = date_dim.d_date_sk AND store_sales.ss_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
  INTERSECT
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER
  WHERE catalog_sales.cs_sold_date_sk = date_dim.d_date_sk AND catalog_sales.cs_bill_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
  INTERSECT
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER
  WHERE web_sales.ws_sold_date_sk = date_dim.d_date_sk AND web_sales.ws_bill_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
) hot_cust
LIMIT 100;

-- Q39: Inventory Deviation
WITH inv AS (
  SELECT w_warehouse_name, w_warehouse_sk, i_item_sk, d_moy,
    STDDEV_SAMP(inv_quantity_on_hand) stdev, AVG(inv_quantity_on_hand) mean
  FROM TPCDS_1000GB.INVENTORY, TPCDS_1000GB.ITEM, TPCDS_1000GB.WAREHOUSE, TPCDS_1000GB.DATE_DIM
  WHERE inv_item_sk = i_item_sk AND inv_warehouse_sk = w_warehouse_sk AND inv_date_sk = d_date_sk AND d_year = 2001
  GROUP BY w_warehouse_name, w_warehouse_sk, i_item_sk, d_moy
)
SELECT inv1.w_warehouse_sk, inv1.i_item_sk, inv1.d_moy, inv1.mean, inv1.stdev, inv2.w_warehouse_sk, inv2.i_item_sk, inv2.d_moy, inv2.mean, inv2.stdev
FROM inv inv1, inv inv2
WHERE inv1.i_item_sk = inv2.i_item_sk AND inv1.w_warehouse_sk = inv2.w_warehouse_sk AND inv1.d_moy = 1 AND inv2.d_moy = 1+1
AND inv1.mean > 0 AND CASE WHEN inv1.mean > 0 THEN inv1.stdev/inv1.mean ELSE NULL END > 1
ORDER BY inv1.w_warehouse_sk, inv1.i_item_sk, inv1.d_moy, inv1.mean, inv1.stdev, inv2.d_moy, inv2.mean, inv2.stdev;

-- Q40: Catalog Web Sales Returns
SELECT w_state, i_item_id,
  SUM(CASE WHEN d_date < DATE '2000-03-11' THEN cs_sales_price - COALESCE(cr_refunded_cash, 0) ELSE 0 END) AS sales_before,
  SUM(CASE WHEN d_date >= DATE '2000-03-11' THEN cs_sales_price - COALESCE(cr_refunded_cash, 0) ELSE 0 END) AS sales_after
FROM TPCDS_1000GB.CATALOG_SALES LEFT OUTER JOIN TPCDS_1000GB.CATALOG_RETURNS ON cs_order_number = cr_order_number AND cs_item_sk = cr_item_sk,
  TPCDS_1000GB.WAREHOUSE, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
WHERE i_current_price BETWEEN 0.99 AND 1.49 AND i_item_sk = cs_item_sk AND cs_warehouse_sk = w_warehouse_sk AND cs_sold_date_sk = d_date_sk
AND d_date BETWEEN DATE '2000-03-11' - INTERVAL '30' DAY AND DATE '2000-03-11' + INTERVAL '30' DAY
GROUP BY w_state, i_item_id
ORDER BY w_state, i_item_id LIMIT 100;

-- Q41: Item Manufacture Color
SELECT DISTINCT i_product_name
FROM TPCDS_1000GB.ITEM i1
WHERE i_manufact_id BETWEEN 738 AND 738+40
AND (SELECT COUNT(*) AS item_cnt FROM TPCDS_1000GB.ITEM
  WHERE (i_manufact = i1.i_manufact AND
    ((i_category = 'Women' AND (i_color = 'powder' OR i_color = 'khaki') AND (i_units = 'Ounce' OR i_units = 'Oz') AND (i_size = 'medium' OR i_size = 'extra large'))
    OR (i_category = 'Women' AND (i_color = 'brown' OR i_color = 'honeydew') AND (i_units = 'Bunch' OR i_units = 'Ton') AND (i_size = 'N/A' OR i_size = 'small'))
    OR (i_category = 'Men' AND (i_color = 'floral' OR i_color = 'deep') AND (i_units = 'N/A' OR i_units = 'Dozen') AND (i_size = 'petite' OR i_size = 'large'))
    OR (i_category = 'Men' AND (i_color = 'light' OR i_color = 'cornflower') AND (i_units = 'Box' OR i_units = 'Pound') AND (i_size = 'medium' OR i_size = 'extra large'))))
) > 0
ORDER BY i_product_name LIMIT 100;

-- Q42: Item Date Sales Monthly
SELECT dt.d_year, item.i_category_id, item.i_category, SUM(ss_ext_sales_price) sum_sales
FROM TPCDS_1000GB.DATE_DIM dt, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM
WHERE dt.d_date_sk = store_sales.ss_sold_date_sk AND store_sales.ss_item_sk = item.i_item_sk AND item.i_manager_id = 1 AND dt.d_moy = 11 AND dt.d_year = 2000
GROUP BY dt.d_year, item.i_category_id, item.i_category
ORDER BY sum_sales DESC, dt.d_year, item.i_category_id, item.i_category LIMIT 100;

-- Q43: Store Weekly Sales
SELECT s_store_name, s_store_id,
  SUM(CASE WHEN d_day_name = 'Sunday' THEN ss_sales_price ELSE NULL END) sun_sales,
  SUM(CASE WHEN d_day_name = 'Monday' THEN ss_sales_price ELSE NULL END) mon_sales,
  SUM(CASE WHEN d_day_name = 'Tuesday' THEN ss_sales_price ELSE NULL END) tue_sales,
  SUM(CASE WHEN d_day_name = 'Wednesday' THEN ss_sales_price ELSE NULL END) wed_sales,
  SUM(CASE WHEN d_day_name = 'Thursday' THEN ss_sales_price ELSE NULL END) thu_sales,
  SUM(CASE WHEN d_day_name = 'Friday' THEN ss_sales_price ELSE NULL END) fri_sales,
  SUM(CASE WHEN d_day_name = 'Saturday' THEN ss_sales_price ELSE NULL END) sat_sales
FROM TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE
WHERE d_date_sk = ss_sold_date_sk AND s_store_sk = ss_store_sk AND s_gmt_offset = -5 AND d_year = 2000
GROUP BY s_store_name, s_store_id
ORDER BY s_store_name, s_store_id, sun_sales, mon_sales, tue_sales, wed_sales, thu_sales, fri_sales, sat_sales LIMIT 100;

-- Q44: Store Sales Rank
SELECT asceding.rnk, i1.i_product_name best_performing, i2.i_product_name worst_performing
FROM (
  SELECT item_sk, RANK() OVER (ORDER BY rank_col ASC) rnk
  FROM (SELECT ss_item_sk item_sk, AVG(ss_net_profit) rank_col FROM TPCDS_1000GB.STORE_SALES ss1 WHERE ss_store_sk = 4 GROUP BY ss_item_sk HAVING AVG(ss_net_profit) > 0.9 * (SELECT AVG(ss_net_profit) rank_col FROM TPCDS_1000GB.STORE_SALES WHERE ss_store_sk = 4 AND ss_addr_sk IS NULL GROUP BY ss_store_sk)) V1
) asceding,
(SELECT item_sk, RANK() OVER (ORDER BY rank_col DESC) rnk
  FROM (SELECT ss_item_sk item_sk, AVG(ss_net_profit) rank_col FROM TPCDS_1000GB.STORE_SALES ss1 WHERE ss_store_sk = 4 GROUP BY ss_item_sk HAVING AVG(ss_net_profit) > 0.9 * (SELECT AVG(ss_net_profit) rank_col FROM TPCDS_1000GB.STORE_SALES WHERE ss_store_sk = 4 AND ss_addr_sk IS NULL GROUP BY ss_store_sk)) V2
) desceding,
TPCDS_1000GB.ITEM i1, TPCDS_1000GB.ITEM i2
WHERE asceding.rnk = desceding.rnk AND i1.i_item_sk = asceding.item_sk AND i2.i_item_sk = desceding.item_sk
ORDER BY asceding.rnk LIMIT 10;

-- Q45: Web Sales by Customer Demographics
SELECT ca_zip, ca_state, SUM(ws_sales_price)
FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.ITEM
WHERE ws_bill_customer_sk = c_customer_sk AND c_current_addr_sk = ca_address_sk AND ws_item_sk = i_item_sk
AND (SUBSTR(ca_zip, 1, 5) IN ('85669', '86197', '88274', '83405', '86475', '85392', '85460', '80348', '81792') OR i_item_id IN (SELECT i_item_id FROM TPCDS_1000GB.ITEM WHERE i_item_sk IN (2, 3, 5, 7, 11, 13, 17, 19, 23, 29)))
AND ws_sold_date_sk = d_date_sk AND d_qoy = 2 AND d_year = 2001
GROUP BY ca_zip, ca_state
ORDER BY ca_zip, ca_state LIMIT 100;

-- Q46: Store Sales Household
SELECT c_last_name, c_first_name, ca_city, bought_city, ss_ticket_number, amt, profit
FROM (
  SELECT ss_ticket_number, ss_customer_sk, ca_city bought_city, SUM(ss_coupon_amt) amt, SUM(ss_net_profit) profit
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.CUSTOMER_ADDRESS
  WHERE store_sales.ss_sold_date_sk = date_dim.d_date_sk AND store_sales.ss_store_sk = store.s_store_sk AND store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk AND store_sales.ss_addr_sk = customer_address.ca_address_sk
  AND (household_demographics.hd_dep_count = 4 OR household_demographics.hd_vehicle_count = 3) AND date_dim.d_dow IN (6, 0) AND date_dim.d_year IN (1999, 1999+1, 1999+2)
  AND store.s_city IN ('Midway', 'Fairview', 'Oak Grove', 'Five Points', 'Pleasant Hill')
  GROUP BY ss_ticket_number, ss_customer_sk, ss_addr_sk, ca_city
) dn, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS current_addr
WHERE ss_customer_sk = c_customer_sk AND customer.c_current_addr_sk = current_addr.ca_address_sk AND current_addr.ca_city <> bought_city
ORDER BY c_last_name, c_first_name, ca_city, bought_city, ss_ticket_number LIMIT 100;

-- Q47: Store Monthly Sales
WITH v1 AS (
  SELECT i_category, i_brand, s_store_name, s_company_name, d_year, d_moy,
    SUM(ss_sales_price) sum_sales,
    AVG(SUM(ss_sales_price)) OVER (PARTITION BY i_category, i_brand, s_store_name, s_company_name, d_year) avg_monthly_sales,
    RANK() OVER (PARTITION BY i_category, i_brand, s_store_name, s_company_name ORDER BY d_year, d_moy) rn
  FROM TPCDS_1000GB.ITEM, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND ss_store_sk = s_store_sk
  AND (d_year = 1999 OR (d_year = 1999-1 AND d_moy = 12) OR (d_year = 1999+1 AND d_moy = 1))
  GROUP BY i_category, i_brand, s_store_name, s_company_name, d_year, d_moy
),
v2 AS (
  SELECT v1.i_category, v1.i_brand, v1.s_store_name, v1.s_company_name, v1.d_year, v1.d_moy, v1.avg_monthly_sales, v1.sum_sales,
    v1_lag.sum_sales psum, v1_lead.sum_sales nsum
  FROM v1, v1 v1_lag, v1 v1_lead
  WHERE v1.i_category = v1_lag.i_category AND v1.i_category = v1_lead.i_category AND v1.i_brand = v1_lag.i_brand AND v1.i_brand = v1_lead.i_brand
  AND v1.s_store_name = v1_lag.s_store_name AND v1.s_store_name = v1_lead.s_store_name AND v1.s_company_name = v1_lag.s_company_name AND v1.s_company_name = v1_lead.s_company_name
  AND v1.rn = v1_lag.rn + 1 AND v1.rn = v1_lead.rn - 1
)
SELECT * FROM v2 WHERE d_year = 1999 AND avg_monthly_sales > 0
AND CASE WHEN avg_monthly_sales > 0 THEN ABS(sum_sales - avg_monthly_sales) / avg_monthly_sales ELSE NULL END > 0.1
ORDER BY sum_sales - avg_monthly_sales, s_store_name LIMIT 100;

-- Q48: Store Sales Price Demographics
SELECT SUM(ss_quantity)
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.DATE_DIM
WHERE s_store_sk = ss_store_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2000
AND ((cd_demo_sk = ss_cdemo_sk AND cd_marital_status = 'M' AND cd_education_status = '4 yr Degree' AND ss_sales_price BETWEEN 100.00 AND 150.00)
  OR (cd_demo_sk = ss_cdemo_sk AND cd_marital_status = 'D' AND cd_education_status = 'Primary' AND ss_sales_price BETWEEN 50.00 AND 100.00)
  OR (cd_demo_sk = ss_cdemo_sk AND cd_marital_status = 'U' AND cd_education_status = 'Advanced Degree' AND ss_sales_price BETWEEN 150.00 AND 200.00))
AND ((ss_addr_sk = ca_address_sk AND ca_country = 'United States' AND ca_state IN ('KY', 'GA', 'NM') AND ss_net_profit BETWEEN 0 AND 2000)
  OR (ss_addr_sk = ca_address_sk AND ca_country = 'United States' AND ca_state IN ('MT', 'OR', 'IN') AND ss_net_profit BETWEEN 150 AND 3000)
  OR (ss_addr_sk = ca_address_sk AND ca_country = 'United States' AND ca_state IN ('WI', 'MO', 'WV') AND ss_net_profit BETWEEN 50 AND 25000));

-- Q49: Channel Returns Analysis
SELECT channel, item, return_ratio, return_rank, currency_rank FROM (
  SELECT 'web' AS channel, web.item, web.return_ratio, web.return_rank, web.currency_rank
  FROM (
    SELECT item, return_ratio, currency_ratio,
      RANK() OVER (ORDER BY return_ratio) AS return_rank,
      RANK() OVER (ORDER BY currency_ratio) AS currency_rank
    FROM (
      SELECT ws.ws_item_sk AS item,
        CAST(SUM(COALESCE(wr.wr_return_quantity, 0)) AS DECIMAL(15,4)) / CAST(SUM(COALESCE(ws.ws_quantity, 0)) AS DECIMAL(15,4)) AS return_ratio,
        CAST(SUM(COALESCE(wr.wr_return_amt, 0)) AS DECIMAL(15,4)) / CAST(SUM(COALESCE(ws.ws_net_paid, 0)) AS DECIMAL(15,4)) AS currency_ratio
      FROM TPCDS_1000GB.WEB_SALES ws LEFT OUTER JOIN TPCDS_1000GB.WEB_RETURNS wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk,
        TPCDS_1000GB.DATE_DIM WHERE wr.wr_return_amt > 10000 AND ws.ws_net_profit > 1 AND ws.ws_net_paid > 0 AND ws.ws_quantity > 0 AND ws_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 12
      GROUP BY ws.ws_item_sk
    ) in_web
  ) web WHERE web.return_rank <= 10 OR web.currency_rank <= 10
  UNION ALL
  SELECT 'catalog' AS channel, cat.item, cat.return_ratio, cat.return_rank, cat.currency_rank
  FROM (
    SELECT item, return_ratio, currency_ratio,
      RANK() OVER (ORDER BY return_ratio) AS return_rank,
      RANK() OVER (ORDER BY currency_ratio) AS currency_rank
    FROM (
      SELECT csales.cs_item_sk AS item,
        CAST(SUM(COALESCE(cret.cr_return_quantity, 0)) AS DECIMAL(15,4)) / CAST(SUM(COALESCE(csales.cs_quantity, 0)) AS DECIMAL(15,4)) AS return_ratio,
        CAST(SUM(COALESCE(cret.cr_return_amount, 0)) AS DECIMAL(15,4)) / CAST(SUM(COALESCE(csales.cs_net_paid, 0)) AS DECIMAL(15,4)) AS currency_ratio
      FROM TPCDS_1000GB.CATALOG_SALES csales LEFT OUTER JOIN TPCDS_1000GB.CATALOG_RETURNS cret ON csales.cs_order_number = cret.cr_order_number AND csales.cs_item_sk = cret.cr_item_sk,
        TPCDS_1000GB.DATE_DIM WHERE cret.cr_return_amount > 10000 AND csales.cs_net_profit > 1 AND csales.cs_net_paid > 0 AND csales.cs_quantity > 0 AND cs_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 12
      GROUP BY csales.cs_item_sk
    ) in_cat
  ) cat WHERE cat.return_rank <= 10 OR cat.currency_rank <= 10
  UNION ALL
  SELECT 'store' AS channel, store.item, store.return_ratio, store.return_rank, store.currency_rank
  FROM (
    SELECT item, return_ratio, currency_ratio,
      RANK() OVER (ORDER BY return_ratio) AS return_rank,
      RANK() OVER (ORDER BY currency_ratio) AS currency_rank
    FROM (
      SELECT sts.ss_item_sk AS item,
        CAST(SUM(COALESCE(sr.sr_return_quantity, 0)) AS DECIMAL(15,4)) / CAST(SUM(COALESCE(sts.ss_quantity, 0)) AS DECIMAL(15,4)) AS return_ratio,
        CAST(SUM(COALESCE(sr.sr_return_amt, 0)) AS DECIMAL(15,4)) / CAST(SUM(COALESCE(sts.ss_net_paid, 0)) AS DECIMAL(15,4)) AS currency_ratio
      FROM TPCDS_1000GB.STORE_SALES sts LEFT OUTER JOIN TPCDS_1000GB.STORE_RETURNS sr ON sts.ss_ticket_number = sr.sr_ticket_number AND sts.ss_item_sk = sr.sr_item_sk,
        TPCDS_1000GB.DATE_DIM WHERE sr.sr_return_amt > 10000 AND sts.ss_net_profit > 1 AND sts.ss_net_paid > 0 AND sts.ss_quantity > 0 AND ss_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 12
      GROUP BY sts.ss_item_sk
    ) in_store
  ) store WHERE store.return_rank <= 10 OR store.currency_rank <= 10
) t
ORDER BY channel, return_rank, currency_rank LIMIT 100;

-- Q50: Store Returns Channel
SELECT s_store_name, s_company_id, s_street_number, s_street_name, s_street_type, s_suite_number, s_city, s_county, s_state, s_zip,
  SUM(CASE WHEN sr_returned_date_sk - ss_sold_date_sk <= 30 THEN 1 ELSE 0 END) AS days_30,
  SUM(CASE WHEN sr_returned_date_sk - ss_sold_date_sk > 30 AND sr_returned_date_sk - ss_sold_date_sk <= 60 THEN 1 ELSE 0 END) AS days_31_60,
  SUM(CASE WHEN sr_returned_date_sk - ss_sold_date_sk > 60 AND sr_returned_date_sk - ss_sold_date_sk <= 90 THEN 1 ELSE 0 END) AS days_61_90,
  SUM(CASE WHEN sr_returned_date_sk - ss_sold_date_sk > 90 AND sr_returned_date_sk - ss_sold_date_sk <= 120 THEN 1 ELSE 0 END) AS days_91_120,
  SUM(CASE WHEN sr_returned_date_sk - ss_sold_date_sk > 120 THEN 1 ELSE 0 END) AS days_gt120
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.STORE, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.DATE_DIM d2
WHERE d2.d_year = 2001 AND d2.d_moy = 8 AND ss_ticket_number = sr_ticket_number AND ss_item_sk = sr_item_sk AND ss_sold_date_sk = d1.d_date_sk
AND sr_returned_date_sk = d2.d_date_sk AND ss_customer_sk = sr_customer_sk AND ss_store_sk = s_store_sk
GROUP BY s_store_name, s_company_id, s_street_number, s_street_name, s_street_type, s_suite_number, s_city, s_county, s_state, s_zip
ORDER BY s_store_name, s_company_id, s_street_number, s_street_name, s_street_type, s_suite_number, s_city, s_county, s_state, s_zip LIMIT 100;

-- Q51: Store Web Cumulative Sales
WITH web_v1 AS (
  SELECT ws_item_sk item_sk, d_date, SUM(SUM(ws_sales_price)) OVER (PARTITION BY ws_item_sk ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cume_sales
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM
  WHERE ws_sold_date_sk = d_date_sk AND d_month_seq BETWEEN 1200 AND 1200+11 AND ws_item_sk IS NOT NULL
  GROUP BY ws_item_sk, d_date
),
store_v1 AS (
  SELECT ss_item_sk item_sk, d_date, SUM(SUM(ss_sales_price)) OVER (PARTITION BY ss_item_sk ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cume_sales
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
  WHERE ss_sold_date_sk = d_date_sk AND d_month_seq BETWEEN 1200 AND 1200+11 AND ss_item_sk IS NOT NULL
  GROUP BY ss_item_sk, d_date
)
SELECT * FROM (
  SELECT item_sk, d_date, web_sales, store_sales,
    MAX(web_sales) OVER (PARTITION BY item_sk ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) web_cumulative,
    MAX(store_sales) OVER (PARTITION BY item_sk ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) store_cumulative
  FROM (
    SELECT CASE WHEN web.item_sk IS NOT NULL THEN web.item_sk ELSE store.item_sk END item_sk,
      CASE WHEN web.d_date IS NOT NULL THEN web.d_date ELSE store.d_date END d_date,
      web.cume_sales web_sales, store.cume_sales store_sales
    FROM web_v1 web FULL OUTER JOIN store_v1 store ON web.item_sk = store.item_sk AND web.d_date = store.d_date
  ) x
) y
WHERE web_cumulative > store_cumulative
ORDER BY item_sk, d_date LIMIT 100;

-- Q52: Item Brand Date Sales
SELECT dt.d_year, item.i_brand_id brand_id, item.i_brand brand, SUM(ss_ext_sales_price) ext_price
FROM TPCDS_1000GB.DATE_DIM dt, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM
WHERE dt.d_date_sk = store_sales.ss_sold_date_sk AND store_sales.ss_item_sk = item.i_item_sk AND item.i_manager_id = 1 AND dt.d_moy = 11 AND dt.d_year = 2000
GROUP BY dt.d_year, item.i_brand, item.i_brand_id
ORDER BY dt.d_year, ext_price DESC, brand_id LIMIT 100;

-- Q53: Item Manufacturer Monthly
SELECT * FROM (
  SELECT i_manufact_id, SUM(ss_sales_price) sum_sales,
    AVG(SUM(ss_sales_price)) OVER (PARTITION BY i_manufact_id) avg_quarterly_sales
  FROM TPCDS_1000GB.ITEM, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND ss_store_sk = s_store_sk
  AND d_month_seq IN (1200, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211)
  AND ((i_category IN ('Books', 'Children', 'Electronics') AND i_class IN ('personal', 'portable', 'reference', 'self-help') AND i_brand IN ('scholaramalgamalg #14', 'scholaramalgamalg #7', 'exportiunivamalg #9', 'scholaramalgamalg #9'))
    OR (i_category IN ('Women', 'Music', 'Men') AND i_class IN ('accessories', 'classical', 'fragrances', 'pants') AND i_brand IN ('amalgimporto #1', 'edu packscholar #1', 'exportiimporto #1', 'importoamalg #1')))
  GROUP BY i_manufact_id, d_qoy
) tmp1
WHERE CASE WHEN avg_quarterly_sales > 0 THEN ABS(sum_sales - avg_quarterly_sales) / avg_quarterly_sales ELSE NULL END > 0.1
ORDER BY avg_quarterly_sales, sum_sales, i_manufact_id LIMIT 100;

-- Q54: Web Store Customer Reach
WITH my_customers AS (
  SELECT DISTINCT c_customer_sk, c_current_addr_sk
  FROM (
    SELECT cs_sold_date_sk sold_date_sk, cs_bill_customer_sk customer_sk, cs_item_sk item_sk
    FROM TPCDS_1000GB.CATALOG_SALES
    UNION ALL
    SELECT ws_sold_date_sk sold_date_sk, ws_bill_customer_sk customer_sk, ws_item_sk item_sk
    FROM TPCDS_1000GB.WEB_SALES
  ) cs_or_ws_sales, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER
  WHERE sold_date_sk = d_date_sk AND item_sk = i_item_sk AND i_category = 'Women' AND i_class = 'maternity'
  AND c_customer_sk = cs_or_ws_sales.customer_sk AND d_moy = 12 AND d_year = 1998
),
my_revenue AS (
  SELECT c_customer_sk, SUM(ss_ext_sales_price) AS revenue
  FROM my_customers, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.STORE, TPCDS_1000GB.DATE_DIM
  WHERE c_current_addr_sk = ca_address_sk AND ca_county = s_county AND ca_state = s_state
  AND ss_sold_date_sk = d_date_sk AND c_customer_sk = ss_customer_sk AND d_month_seq BETWEEN (SELECT DISTINCT d_month_seq+1 FROM TPCDS_1000GB.DATE_DIM WHERE d_year = 1998 AND d_moy = 12) AND (SELECT DISTINCT d_month_seq+3 FROM TPCDS_1000GB.DATE_DIM WHERE d_year = 1998 AND d_moy = 12)
  GROUP BY c_customer_sk
)
SELECT COUNT(*) AS customer_count, SUM(revenue) AS total_revenue FROM (
  SELECT c_customer_sk, SUM(revenue) AS revenue FROM my_revenue GROUP BY c_customer_sk
) t
LIMIT 100;

-- Q55: Item Brand Month Sales
SELECT i_brand_id brand_id, i_brand brand, SUM(ss_ext_sales_price) ext_price
FROM TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM
WHERE d_date_sk = ss_sold_date_sk AND ss_item_sk = i_item_sk AND i_manager_id = 28 AND d_moy = 11 AND d_year = 1999
GROUP BY i_brand, i_brand_id
ORDER BY ext_price DESC, i_brand_id LIMIT 100;

-- Q56: Store Catalog Web by Zip
SELECT i_item_id, SUM(total_sales) total_sales FROM (
  SELECT i_item_id, SUM(ss_ext_sales_price) total_sales
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_1000GB.ITEM WHERE i_color IN ('slate', 'blanched', 'burnished'))
  AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 2
  AND ss_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
  UNION ALL
  SELECT i_item_id, SUM(cs_ext_sales_price) total_sales
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_1000GB.ITEM WHERE i_color IN ('slate', 'blanched', 'burnished'))
  AND cs_item_sk = i_item_sk AND cs_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 2
  AND cs_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
  UNION ALL
  SELECT i_item_id, SUM(ws_ext_sales_price) total_sales
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_1000GB.ITEM WHERE i_color IN ('slate', 'blanched', 'burnished'))
  AND ws_item_sk = i_item_sk AND ws_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy = 2
  AND ws_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
) tmp1
GROUP BY i_item_id
ORDER BY total_sales, i_item_id LIMIT 100;

-- Q57: Catalog Monthly Sales
WITH v1 AS (
  SELECT i_category, i_brand, cc_name, d_year, d_moy,
    SUM(cs_sales_price) sum_sales,
    AVG(SUM(cs_sales_price)) OVER (PARTITION BY i_category, i_brand, cc_name, d_year) avg_monthly_sales,
    RANK() OVER (PARTITION BY i_category, i_brand, cc_name ORDER BY d_year, d_moy) rn
  FROM TPCDS_1000GB.ITEM, TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CALL_CENTER
  WHERE cs_item_sk = i_item_sk AND cs_sold_date_sk = d_date_sk AND cc_call_center_sk = cs_call_center_sk
  AND (d_year = 1999 OR (d_year = 1999-1 AND d_moy = 12) OR (d_year = 1999+1 AND d_moy = 1))
  GROUP BY i_category, i_brand, cc_name, d_year, d_moy
),
v2 AS (
  SELECT v1.i_category, v1.i_brand, v1.cc_name, v1.d_year, v1.d_moy, v1.avg_monthly_sales, v1.sum_sales,
    v1_lag.sum_sales psum, v1_lead.sum_sales nsum
  FROM v1, v1 v1_lag, v1 v1_lead
  WHERE v1.i_category = v1_lag.i_category AND v1.i_category = v1_lead.i_category AND v1.i_brand = v1_lag.i_brand AND v1.i_brand = v1_lead.i_brand
  AND v1.cc_name = v1_lag.cc_name AND v1.cc_name = v1_lead.cc_name
  AND v1.rn = v1_lag.rn + 1 AND v1.rn = v1_lead.rn - 1
)
SELECT * FROM v2 WHERE d_year = 1999 AND avg_monthly_sales > 0
AND CASE WHEN avg_monthly_sales > 0 THEN ABS(sum_sales - avg_monthly_sales) / avg_monthly_sales ELSE NULL END > 0.1
ORDER BY sum_sales - avg_monthly_sales, cc_name LIMIT 100;

-- Q58: Cross Channel Item Date Sales
WITH ss_items AS (
  SELECT i_item_id item_id, SUM(ss_ext_sales_price) ss_item_rev
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE ss_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1000GB.DATE_DIM WHERE d_week_seq = (SELECT d_week_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_date = DATE '2000-01-03'))
  AND ss_sold_date_sk = d_date_sk
  GROUP BY i_item_id
),
cs_items AS (
  SELECT i_item_id item_id, SUM(cs_ext_sales_price) cs_item_rev
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE cs_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1000GB.DATE_DIM WHERE d_week_seq = (SELECT d_week_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_date = DATE '2000-01-03'))
  AND cs_sold_date_sk = d_date_sk
  GROUP BY i_item_id
),
ws_items AS (
  SELECT i_item_id item_id, SUM(ws_ext_sales_price) ws_item_rev
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE ws_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1000GB.DATE_DIM WHERE d_week_seq = (SELECT d_week_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_date = DATE '2000-01-03'))
  AND ws_sold_date_sk = d_date_sk
  GROUP BY i_item_id
)
SELECT ss_items.item_id, ss_item_rev, ss_item_rev/(ss_item_rev+cs_item_rev+ws_item_rev)/3 * 100 ss_dev,
  cs_item_rev, cs_item_rev/(ss_item_rev+cs_item_rev+ws_item_rev)/3 * 100 cs_dev,
  ws_item_rev, ws_item_rev/(ss_item_rev+cs_item_rev+ws_item_rev)/3 * 100 ws_dev,
  (ss_item_rev+cs_item_rev+ws_item_rev)/3 average
FROM ss_items, cs_items, ws_items
WHERE ss_items.item_id = cs_items.item_id AND ss_items.item_id = ws_items.item_id
AND ss_item_rev >= 0.9 * cs_item_rev AND ss_item_rev <= 1.1 * cs_item_rev
AND ss_item_rev >= 0.9 * ws_item_rev AND ss_item_rev <= 1.1 * ws_item_rev
AND cs_item_rev >= 0.9 * ws_item_rev AND cs_item_rev <= 1.1 * ws_item_rev
ORDER BY ss_items.item_id, ss_item_rev LIMIT 100;

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
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
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
  FROM wss, TPCDS_1000GB.STORE, TPCDS_1000GB.DATE_DIM d
  WHERE d.d_week_seq = wss.d_week_seq AND ss_store_sk = s_store_sk AND d_month_seq BETWEEN 1212 AND 1212+11
) y1,
(SELECT s_store_id, wss.d_week_seq AS wk_seq, sun_sales AS sun_sales2, mon_sales AS mon_sales2, tue_sales AS tue_sales2, wed_sales AS wed_sales2, thu_sales AS thu_sales2, fri_sales AS fri_sales2, sat_sales AS sat_sales2
  FROM wss, TPCDS_1000GB.STORE, TPCDS_1000GB.DATE_DIM d
  WHERE d.d_week_seq = wss.d_week_seq AND ss_store_sk = s_store_sk AND d_month_seq BETWEEN 1212+12 AND 1212+23
) y2
WHERE y1.wk_seq = y2.wk_seq - 52
ORDER BY s_store_name1, d_week_seq1, sun_ratio LIMIT 100;

-- Q60: Multi-Channel Sales by Zip
SELECT i_item_id, SUM(total_sales) total_sales FROM (
  SELECT i_item_id, SUM(ss_ext_sales_price) total_sales
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Music'))
  AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 9
  AND ss_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
  UNION ALL
  SELECT i_item_id, SUM(cs_ext_sales_price) total_sales
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Music'))
  AND cs_item_sk = i_item_sk AND cs_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 9
  AND cs_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
  UNION ALL
  SELECT i_item_id, SUM(ws_ext_sales_price) total_sales
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE i_item_id IN (SELECT i_item_id FROM TPCDS_1000GB.ITEM WHERE i_category IN ('Music'))
  AND ws_item_sk = i_item_sk AND ws_sold_date_sk = d_date_sk AND d_year = 1998 AND d_moy = 9
  AND ws_bill_addr_sk = ca_address_sk AND ca_gmt_offset = -5
  GROUP BY i_item_id
) tmp1
GROUP BY i_item_id
ORDER BY i_item_id, total_sales LIMIT 100;

-- Q61: Promotional Sales Analysis
SELECT promotions, total, CAST(promotions AS DECIMAL(15,4))/CAST(total AS DECIMAL(15,4))*100
FROM (
  SELECT SUM(ss_ext_sales_price) promotions
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE, TPCDS_1000GB.PROMOTION, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE ss_sold_date_sk = d_date_sk AND ss_store_sk = s_store_sk AND ss_promo_sk = p_promo_sk AND ss_customer_sk = c_customer_sk AND ca_address_sk = c_current_addr_sk AND ss_item_sk = i_item_sk
  AND ca_gmt_offset = -5 AND i_category = 'Jewelry' AND (p_channel_dmail = 'Y' OR p_channel_email = 'Y' OR p_channel_tv = 'Y') AND s_gmt_offset = -5 AND d_year = 1998 AND d_moy = 11
) promotional_sales,
(SELECT SUM(ss_ext_sales_price) total
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.ITEM
  WHERE ss_sold_date_sk = d_date_sk AND ss_store_sk = s_store_sk AND ss_customer_sk = c_customer_sk AND ca_address_sk = c_current_addr_sk AND ss_item_sk = i_item_sk
  AND ca_gmt_offset = -5 AND i_category = 'Jewelry' AND s_gmt_offset = -5 AND d_year = 1998 AND d_moy = 11
) all_sales
ORDER BY promotions, total LIMIT 100;

-- Q62: Web Ship Date Delay
SELECT SUBSTR(w_warehouse_name, 1, 20) wh_name, sm_type, web_name,
  SUM(CASE WHEN ws_ship_date_sk - ws_sold_date_sk <= 30 THEN 1 ELSE 0 END) AS days_30,
  SUM(CASE WHEN ws_ship_date_sk - ws_sold_date_sk > 30 AND ws_ship_date_sk - ws_sold_date_sk <= 60 THEN 1 ELSE 0 END) AS days_31_60,
  SUM(CASE WHEN ws_ship_date_sk - ws_sold_date_sk > 60 AND ws_ship_date_sk - ws_sold_date_sk <= 90 THEN 1 ELSE 0 END) AS days_61_90,
  SUM(CASE WHEN ws_ship_date_sk - ws_sold_date_sk > 90 AND ws_ship_date_sk - ws_sold_date_sk <= 120 THEN 1 ELSE 0 END) AS days_91_120,
  SUM(CASE WHEN ws_ship_date_sk - ws_sold_date_sk > 120 THEN 1 ELSE 0 END) AS days_gt120
FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.WAREHOUSE, TPCDS_1000GB.SHIP_MODE, TPCDS_1000GB.WEB_SITE, TPCDS_1000GB.DATE_DIM
WHERE d_month_seq BETWEEN 1200 AND 1200+11 AND ws_ship_date_sk = d_date_sk AND ws_warehouse_sk = w_warehouse_sk AND ws_ship_mode_sk = sm_ship_mode_sk AND ws_web_site_sk = web_site_sk
GROUP BY SUBSTR(w_warehouse_name, 1, 20), sm_type, web_name
ORDER BY SUBSTR(w_warehouse_name, 1, 20), sm_type, web_name LIMIT 100;

-- Q63: Item Manager Monthly Sales
SELECT * FROM (
  SELECT i_manager_id, SUM(ss_sales_price) sum_sales,
    AVG(SUM(ss_sales_price)) OVER (PARTITION BY i_manager_id) avg_monthly_sales
  FROM TPCDS_1000GB.ITEM, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND ss_store_sk = s_store_sk
  AND d_month_seq IN (1200, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211)
  AND ((i_category IN ('Books', 'Children', 'Electronics') AND i_class IN ('personal', 'portable', 'reference', 'self-help') AND i_brand IN ('scholaramalgamalg #14', 'scholaramalgamalg #7', 'exportiunivamalg #9', 'scholaramalgamalg #9'))
    OR (i_category IN ('Women', 'Music', 'Men') AND i_class IN ('accessories', 'classical', 'fragrances', 'pants') AND i_brand IN ('amalgimporto #1', 'edu packscholar #1', 'exportiimporto #1', 'importoamalg #1')))
  GROUP BY i_manager_id, d_moy
) tmp1
WHERE CASE WHEN avg_monthly_sales > 0 THEN ABS(sum_sales - avg_monthly_sales) / avg_monthly_sales ELSE NULL END > 0.1
ORDER BY i_manager_id, avg_monthly_sales, sum_sales LIMIT 100;

-- Q64: Store Sales Customer Price
WITH cs_ui AS (
  SELECT cs_item_sk, SUM(cs_ext_list_price) AS sale, SUM(cr_refunded_cash+cr_reversed_charge+cr_store_credit) AS refund
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.CATALOG_RETURNS
  WHERE cs_item_sk = cr_item_sk AND cs_order_number = cr_order_number
  GROUP BY cs_item_sk
  HAVING SUM(cs_ext_list_price) > 2 * SUM(cr_refunded_cash+cr_reversed_charge+cr_store_credit)
),
cross_sales AS (
  SELECT i_product_name product_name, i_item_sk item_sk, s_store_name store_name, s_zip store_zip, ad1.ca_street_number b_street_number, ad1.ca_street_name b_street_name, ad1.ca_city b_city, ad1.ca_zip b_zip,
    ad2.ca_street_number c_street_number, ad2.ca_street_name c_street_name, ad2.ca_city c_city, ad2.ca_zip c_zip,
    d1.d_year AS syear, d2.d_year AS fsyear, d3.d_year AS s2year, COUNT(*) cnt, SUM(ss_wholesale_cost) s1, SUM(ss_list_price) s2, SUM(ss_coupon_amt) s3
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE_RETURNS, cs_ui, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.DATE_DIM d2, TPCDS_1000GB.DATE_DIM d3, TPCDS_1000GB.STORE, TPCDS_1000GB.CUSTOMER,
    TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS cd1, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS cd2, TPCDS_1000GB.PROMOTION, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS hd1, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS hd2,
    TPCDS_1000GB.CUSTOMER_ADDRESS ad1, TPCDS_1000GB.CUSTOMER_ADDRESS ad2, TPCDS_1000GB.INCOME_BAND ib1, TPCDS_1000GB.INCOME_BAND ib2, TPCDS_1000GB.ITEM
  WHERE ss_store_sk = s_store_sk AND ss_sold_date_sk = d1.d_date_sk AND ss_customer_sk = c_customer_sk AND ss_cdemo_sk = cd1.cd_demo_sk AND ss_hdemo_sk = hd1.hd_demo_sk AND ss_addr_sk = ad1.ca_address_sk
  AND ss_item_sk = i_item_sk AND ss_item_sk = sr_item_sk AND ss_ticket_number = sr_ticket_number AND ss_item_sk = cs_item_sk
  AND c_current_cdemo_sk = cd2.cd_demo_sk AND c_current_hdemo_sk = hd2.hd_demo_sk AND c_current_addr_sk = ad2.ca_address_sk
  AND c_first_sales_date_sk = d2.d_date_sk AND c_first_shipto_date_sk = d3.d_date_sk AND ss_promo_sk = p_promo_sk AND hd1.hd_income_band_sk = ib1.ib_income_band_sk AND hd2.hd_income_band_sk = ib2.ib_income_band_sk
  AND cd1.cd_marital_status <> cd2.cd_marital_status AND i_color IN ('purple', 'burlywood', 'indian', 'spring', 'floral', 'medium')
  AND i_current_price BETWEEN 64 AND 64+10 AND i_current_price BETWEEN 64+1 AND 64+15
  GROUP BY i_product_name, i_item_sk, s_store_name, s_zip, ad1.ca_street_number, ad1.ca_street_name, ad1.ca_city, ad1.ca_zip,
    ad2.ca_street_number, ad2.ca_street_name, ad2.ca_city, ad2.ca_zip, d1.d_year, d2.d_year, d3.d_year
)
SELECT cs1.product_name, cs1.store_name, cs1.store_zip, cs1.b_street_number, cs1.b_street_name, cs1.b_city, cs1.b_zip,
  cs1.c_street_number, cs1.c_street_name, cs1.c_city, cs1.c_zip, cs1.syear, cs1.cnt, cs1.s1 AS s11, cs1.s2 AS s21, cs1.s3 AS s31, cs2.s1 AS s12, cs2.s2 AS s22, cs2.s3 AS s32, cs2.syear, cs2.cnt
FROM cross_sales cs1, cross_sales cs2
WHERE cs1.item_sk = cs2.item_sk AND cs1.syear = 2001 AND cs2.syear = 2001+1 AND cs2.cnt <= cs1.cnt AND cs1.store_name = cs2.store_name AND cs1.store_zip = cs2.store_zip
ORDER BY cs1.product_name, cs1.store_name, cs2.cnt, cs1.s1, cs2.s1 LIMIT 100;

-- Q65: Store Item Revenue
SELECT s_store_name, i_item_desc, sc.revenue, i_current_price, i_wholesale_cost, i_brand
FROM TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM,
  (SELECT ss_store_sk, ss_item_sk, SUM(ss_sales_price) AS revenue
   FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
   WHERE ss_sold_date_sk = d_date_sk AND d_month_seq BETWEEN 1176 AND 1176+11
   GROUP BY ss_store_sk, ss_item_sk
  ) sc,
  (SELECT ss_store_sk, AVG(revenue) AS ave
   FROM (SELECT ss_store_sk, ss_item_sk, SUM(ss_sales_price) AS revenue
         FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
         WHERE ss_sold_date_sk = d_date_sk AND d_month_seq BETWEEN 1176 AND 1176+11
         GROUP BY ss_store_sk, ss_item_sk) sa
   GROUP BY ss_store_sk
  ) sb
WHERE s_store_sk = sc.ss_store_sk AND sc.ss_store_sk = sb.ss_store_sk AND sc.revenue <= 0.1 * sb.ave AND s_store_sk = sc.ss_store_sk AND i_item_sk = sc.ss_item_sk
ORDER BY s_store_name, i_item_desc LIMIT 100;

-- Q66: Warehouse Ship Mode Sales
SELECT w_warehouse_name, w_warehouse_sq_ft, w_city, w_county, w_state, w_country,
  ship_carriers, d_year,
  SUM(jan_sales) AS jan_sales, SUM(feb_sales) AS feb_sales, SUM(mar_sales) AS mar_sales, SUM(apr_sales) AS apr_sales,
  SUM(may_sales) AS may_sales, SUM(jun_sales) AS jun_sales, SUM(jul_sales) AS jul_sales, SUM(aug_sales) AS aug_sales,
  SUM(sep_sales) AS sep_sales, SUM(oct_sales) AS oct_sales, SUM(nov_sales) AS nov_sales, SUM(dec_sales) AS dec_sales,
  SUM(jan_sales/w_warehouse_sq_ft) AS jan_sales_per_sq_foot, SUM(feb_sales/w_warehouse_sq_ft) AS feb_sales_per_sq_foot,
  SUM(mar_sales/w_warehouse_sq_ft) AS mar_sales_per_sq_foot, SUM(apr_sales/w_warehouse_sq_ft) AS apr_sales_per_sq_foot,
  SUM(may_sales/w_warehouse_sq_ft) AS may_sales_per_sq_foot, SUM(jun_sales/w_warehouse_sq_ft) AS jun_sales_per_sq_foot,
  SUM(jul_sales/w_warehouse_sq_ft) AS jul_sales_per_sq_foot, SUM(aug_sales/w_warehouse_sq_ft) AS aug_sales_per_sq_foot,
  SUM(sep_sales/w_warehouse_sq_ft) AS sep_sales_per_sq_foot, SUM(oct_sales/w_warehouse_sq_ft) AS oct_sales_per_sq_foot,
  SUM(nov_sales/w_warehouse_sq_ft) AS nov_sales_per_sq_foot, SUM(dec_sales/w_warehouse_sq_ft) AS dec_sales_per_sq_foot,
  SUM(jan_net) AS jan_net, SUM(feb_net) AS feb_net, SUM(mar_net) AS mar_net, SUM(apr_net) AS apr_net,
  SUM(may_net) AS may_net, SUM(jun_net) AS jun_net, SUM(jul_net) AS jul_net, SUM(aug_net) AS aug_net,
  SUM(sep_net) AS sep_net, SUM(oct_net) AS oct_net, SUM(nov_net) AS nov_net, SUM(dec_net) AS dec_net
FROM (
  SELECT w_warehouse_name, w_warehouse_sq_ft, w_city, w_county, w_state, w_country,
    CONCAT('DHL', ',', 'BARIAN') AS ship_carriers, d_year AS d_year,
    SUM(CASE WHEN d_moy = 1 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS jan_sales,
    SUM(CASE WHEN d_moy = 2 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS feb_sales,
    SUM(CASE WHEN d_moy = 3 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS mar_sales,
    SUM(CASE WHEN d_moy = 4 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS apr_sales,
    SUM(CASE WHEN d_moy = 5 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS may_sales,
    SUM(CASE WHEN d_moy = 6 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS jun_sales,
    SUM(CASE WHEN d_moy = 7 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS jul_sales,
    SUM(CASE WHEN d_moy = 8 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS aug_sales,
    SUM(CASE WHEN d_moy = 9 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS sep_sales,
    SUM(CASE WHEN d_moy = 10 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS oct_sales,
    SUM(CASE WHEN d_moy = 11 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS nov_sales,
    SUM(CASE WHEN d_moy = 12 THEN ws_ext_sales_price * ws_quantity ELSE 0 END) AS dec_sales,
    SUM(CASE WHEN d_moy = 1 THEN ws_net_paid * ws_quantity ELSE 0 END) AS jan_net,
    SUM(CASE WHEN d_moy = 2 THEN ws_net_paid * ws_quantity ELSE 0 END) AS feb_net,
    SUM(CASE WHEN d_moy = 3 THEN ws_net_paid * ws_quantity ELSE 0 END) AS mar_net,
    SUM(CASE WHEN d_moy = 4 THEN ws_net_paid * ws_quantity ELSE 0 END) AS apr_net,
    SUM(CASE WHEN d_moy = 5 THEN ws_net_paid * ws_quantity ELSE 0 END) AS may_net,
    SUM(CASE WHEN d_moy = 6 THEN ws_net_paid * ws_quantity ELSE 0 END) AS jun_net,
    SUM(CASE WHEN d_moy = 7 THEN ws_net_paid * ws_quantity ELSE 0 END) AS jul_net,
    SUM(CASE WHEN d_moy = 8 THEN ws_net_paid * ws_quantity ELSE 0 END) AS aug_net,
    SUM(CASE WHEN d_moy = 9 THEN ws_net_paid * ws_quantity ELSE 0 END) AS sep_net,
    SUM(CASE WHEN d_moy = 10 THEN ws_net_paid * ws_quantity ELSE 0 END) AS oct_net,
    SUM(CASE WHEN d_moy = 11 THEN ws_net_paid * ws_quantity ELSE 0 END) AS nov_net,
    SUM(CASE WHEN d_moy = 12 THEN ws_net_paid * ws_quantity ELSE 0 END) AS dec_net
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.WAREHOUSE, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.SHIP_MODE
  WHERE ws_warehouse_sk = w_warehouse_sk AND ws_sold_date_sk = d_date_sk AND ws_sold_time_sk = t_time_sk AND ws_ship_mode_sk = sm_ship_mode_sk
  AND d_year = 2001 AND t_time BETWEEN 30838 AND 30838+28800 AND sm_carrier IN ('DHL', 'BARIAN')
  GROUP BY w_warehouse_name, w_warehouse_sq_ft, w_city, w_county, w_state, w_country, d_year
  UNION ALL
  SELECT w_warehouse_name, w_warehouse_sq_ft, w_city, w_county, w_state, w_country,
    CONCAT('DHL', ',', 'BARIAN') AS ship_carriers, d_year AS d_year,
    SUM(CASE WHEN d_moy = 1 THEN cs_sales_price * cs_quantity ELSE 0 END) AS jan_sales,
    SUM(CASE WHEN d_moy = 2 THEN cs_sales_price * cs_quantity ELSE 0 END) AS feb_sales,
    SUM(CASE WHEN d_moy = 3 THEN cs_sales_price * cs_quantity ELSE 0 END) AS mar_sales,
    SUM(CASE WHEN d_moy = 4 THEN cs_sales_price * cs_quantity ELSE 0 END) AS apr_sales,
    SUM(CASE WHEN d_moy = 5 THEN cs_sales_price * cs_quantity ELSE 0 END) AS may_sales,
    SUM(CASE WHEN d_moy = 6 THEN cs_sales_price * cs_quantity ELSE 0 END) AS jun_sales,
    SUM(CASE WHEN d_moy = 7 THEN cs_sales_price * cs_quantity ELSE 0 END) AS jul_sales,
    SUM(CASE WHEN d_moy = 8 THEN cs_sales_price * cs_quantity ELSE 0 END) AS aug_sales,
    SUM(CASE WHEN d_moy = 9 THEN cs_sales_price * cs_quantity ELSE 0 END) AS sep_sales,
    SUM(CASE WHEN d_moy = 10 THEN cs_sales_price * cs_quantity ELSE 0 END) AS oct_sales,
    SUM(CASE WHEN d_moy = 11 THEN cs_sales_price * cs_quantity ELSE 0 END) AS nov_sales,
    SUM(CASE WHEN d_moy = 12 THEN cs_sales_price * cs_quantity ELSE 0 END) AS dec_sales,
    SUM(CASE WHEN d_moy = 1 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS jan_net,
    SUM(CASE WHEN d_moy = 2 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS feb_net,
    SUM(CASE WHEN d_moy = 3 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS mar_net,
    SUM(CASE WHEN d_moy = 4 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS apr_net,
    SUM(CASE WHEN d_moy = 5 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS may_net,
    SUM(CASE WHEN d_moy = 6 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS jun_net,
    SUM(CASE WHEN d_moy = 7 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS jul_net,
    SUM(CASE WHEN d_moy = 8 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS aug_net,
    SUM(CASE WHEN d_moy = 9 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS sep_net,
    SUM(CASE WHEN d_moy = 10 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS oct_net,
    SUM(CASE WHEN d_moy = 11 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS nov_net,
    SUM(CASE WHEN d_moy = 12 THEN cs_net_paid_inc_tax * cs_quantity ELSE 0 END) AS dec_net
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.WAREHOUSE, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.SHIP_MODE
  WHERE cs_warehouse_sk = w_warehouse_sk AND cs_sold_date_sk = d_date_sk AND cs_sold_time_sk = t_time_sk AND cs_ship_mode_sk = sm_ship_mode_sk
  AND d_year = 2001 AND t_time BETWEEN 30838 AND 30838+28800 AND sm_carrier IN ('DHL', 'BARIAN')
  GROUP BY w_warehouse_name, w_warehouse_sq_ft, w_city, w_county, w_state, w_country, d_year
) x
GROUP BY w_warehouse_name, w_warehouse_sq_ft, w_city, w_county, w_state, w_country, ship_carriers, d_year
ORDER BY w_warehouse_name LIMIT 100;

-- Q67: Store Sales Rollup
SELECT * FROM (
  SELECT i_category, i_class, i_brand, i_product_name, d_year, d_qoy, d_moy, s_store_id,
    SUM(COALESCE(ss_sales_price * ss_quantity, 0)) sumsales,
    RANK() OVER (PARTITION BY i_category ORDER BY SUM(COALESCE(ss_sales_price * ss_quantity, 0)) DESC) rk
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM
  WHERE ss_sold_date_sk = d_date_sk AND ss_item_sk = i_item_sk AND ss_store_sk = s_store_sk
  AND d_month_seq BETWEEN 1200 AND 1200+11
  GROUP BY ROLLUP(i_category, i_class, i_brand, i_product_name, d_year, d_qoy, d_moy, s_store_id)
) dw1
WHERE rk <= 100
ORDER BY i_category, i_class, i_brand, i_product_name, d_year, d_qoy, d_moy, s_store_id, sumsales, rk LIMIT 100;

-- Q68: Store Sales Address
SELECT c_last_name, c_first_name, ca_city, bought_city, ss_ticket_number, extended_price, extended_tax, list_price
FROM (
  SELECT ss_ticket_number, ss_customer_sk, ca_city bought_city, SUM(ss_ext_sales_price) extended_price, SUM(ss_ext_list_price) list_price, SUM(ss_ext_tax) extended_tax
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.CUSTOMER_ADDRESS
  WHERE store_sales.ss_sold_date_sk = date_dim.d_date_sk AND store_sales.ss_store_sk = store.s_store_sk AND store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk AND store_sales.ss_addr_sk = customer_address.ca_address_sk
  AND date_dim.d_dom BETWEEN 1 AND 2 AND (household_demographics.hd_dep_count = 4 OR household_demographics.hd_vehicle_count = 3) AND date_dim.d_year IN (1999, 1999+1, 1999+2)
  AND store.s_city IN ('Fairview', 'Midway')
  GROUP BY ss_ticket_number, ss_customer_sk, ss_addr_sk, ca_city
) dn, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS current_addr
WHERE ss_customer_sk = c_customer_sk AND customer.c_current_addr_sk = current_addr.ca_address_sk AND current_addr.ca_city <> bought_city
ORDER BY c_last_name, ss_ticket_number LIMIT 100;

-- Q69: Customer Channel Activity
SELECT cd_gender, cd_marital_status, cd_education_status, COUNT(*) cnt1, cd_purchase_estimate, COUNT(*) cnt2, cd_credit_rating, COUNT(*) cnt3
FROM TPCDS_1000GB.CUSTOMER c, TPCDS_1000GB.CUSTOMER_ADDRESS ca, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS
WHERE c.c_current_addr_sk = ca.ca_address_sk AND ca_state IN ('KY', 'GA', 'NM') AND cd_demo_sk = c.c_current_cdemo_sk
AND EXISTS (SELECT * FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy BETWEEN 4 AND 4+2)
AND NOT EXISTS (SELECT * FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = ws_bill_customer_sk AND ws_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy BETWEEN 4 AND 4+2)
AND NOT EXISTS (SELECT * FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM WHERE c.c_customer_sk = cs_ship_customer_sk AND cs_sold_date_sk = d_date_sk AND d_year = 2001 AND d_moy BETWEEN 4 AND 4+2)
GROUP BY cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, cd_credit_rating
ORDER BY cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, cd_credit_rating
LIMIT 100;

-- Q70: Store Sales County Rollup
SELECT SUM(ss_net_profit) AS total_sum, s_state, s_county,
  GROUPING(s_state)+GROUPING(s_county) AS lochierarchy,
  RANK() OVER (PARTITION BY GROUPING(s_state)+GROUPING(s_county), CASE WHEN GROUPING(s_county) = 0 THEN s_state END ORDER BY SUM(ss_net_profit) DESC) AS rank_within_parent
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.STORE
WHERE d1.d_month_seq BETWEEN 1200 AND 1200+11 AND d1.d_date_sk = ss_sold_date_sk AND s_store_sk = ss_store_sk
AND s_state IN (
  SELECT s_state FROM (
    SELECT s_state AS s_state, RANK() OVER (PARTITION BY s_state ORDER BY SUM(ss_net_profit) DESC) AS ranking
    FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.STORE, TPCDS_1000GB.DATE_DIM
    WHERE d_month_seq BETWEEN 1200 AND 1200+11 AND d_date_sk = ss_sold_date_sk AND s_store_sk = ss_store_sk
    GROUP BY s_state, s_county
  ) tmp1 WHERE ranking <= 5
)
GROUP BY ROLLUP(s_state, s_county)
ORDER BY lochierarchy DESC, CASE WHEN lochierarchy = 0 THEN s_state END, rank_within_parent LIMIT 100;

-- Q71: Item Brand Channel Monthly
SELECT i_brand_id brand_id, i_brand brand, t_hour, t_minute, SUM(ext_price) ext_price
FROM TPCDS_1000GB.ITEM,
  (SELECT ws_ext_sales_price AS ext_price, ws_sold_date_sk AS sold_date_sk, ws_item_sk AS sold_item_sk, ws_sold_time_sk AS time_sk FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM WHERE d_date_sk = ws_sold_date_sk AND d_moy = 11 AND d_year = 1999
   UNION ALL
   SELECT cs_ext_sales_price AS ext_price, cs_sold_date_sk AS sold_date_sk, cs_item_sk AS sold_item_sk, cs_sold_time_sk AS time_sk FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM WHERE d_date_sk = cs_sold_date_sk AND d_moy = 11 AND d_year = 1999
   UNION ALL
   SELECT ss_ext_sales_price AS ext_price, ss_sold_date_sk AS sold_date_sk, ss_item_sk AS sold_item_sk, ss_sold_time_sk AS time_sk FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM WHERE d_date_sk = ss_sold_date_sk AND d_moy = 11 AND d_year = 1999
  ) tmp, TPCDS_1000GB.TIME_DIM
WHERE sold_item_sk = i_item_sk AND i_manager_id = 1 AND t_time_sk = time_sk AND (t_meal_time = 'breakfast' OR t_meal_time = 'dinner')
GROUP BY i_brand_id, i_brand, t_hour, t_minute
ORDER BY ext_price DESC, i_brand_id LIMIT 100;

-- Q72: Catalog Inventory Promo
SELECT i_item_desc, w_warehouse_name, d1.d_week_seq,
  SUM(CASE WHEN p_promo_sk IS NULL THEN 1 ELSE 0 END) no_promo,
  SUM(CASE WHEN p_promo_sk IS NOT NULL THEN 1 ELSE 0 END) promo,
  COUNT(*) total_cnt
FROM TPCDS_1000GB.CATALOG_SALES
  JOIN TPCDS_1000GB.INVENTORY ON cs_item_sk = inv_item_sk
  JOIN TPCDS_1000GB.WAREHOUSE ON w_warehouse_sk = inv_warehouse_sk
  JOIN TPCDS_1000GB.ITEM ON i_item_sk = cs_item_sk
  JOIN TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS ON cs_bill_cdemo_sk = cd_demo_sk
  JOIN TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS ON cs_bill_hdemo_sk = hd_demo_sk
  JOIN TPCDS_1000GB.DATE_DIM d1 ON cs_sold_date_sk = d1.d_date_sk
  JOIN TPCDS_1000GB.DATE_DIM d2 ON inv_date_sk = d2.d_date_sk
  JOIN TPCDS_1000GB.DATE_DIM d3 ON cs_ship_date_sk = d3.d_date_sk
  LEFT OUTER JOIN TPCDS_1000GB.PROMOTION ON cs_promo_sk = p_promo_sk
WHERE d1.d_week_seq = d2.d_week_seq AND inv_quantity_on_hand < cs_quantity
AND d3.d_date > d1.d_date + INTERVAL '5' DAY AND hd_buy_potential = '>10000' AND d1.d_year = 1999 AND cd_marital_status = 'D'
GROUP BY i_item_desc, w_warehouse_name, d1.d_week_seq
ORDER BY total_cnt DESC, i_item_desc, w_warehouse_name, d1.d_week_seq LIMIT 100;

-- Q73: Store Sales Household County
SELECT c_last_name, c_first_name, c_salutation, c_preferred_cust_flag, ss_ticket_number, cnt
FROM (
  SELECT ss_ticket_number, ss_customer_sk, COUNT(*) cnt
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS
  WHERE store_sales.ss_sold_date_sk = date_dim.d_date_sk AND store_sales.ss_store_sk = store.s_store_sk AND store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
  AND (date_dim.d_dom BETWEEN 1 AND 3 OR date_dim.d_dom BETWEEN 25 AND 28) AND (household_demographics.hd_buy_potential = '>10000' OR household_demographics.hd_buy_potential = 'Unknown')
  AND household_demographics.hd_vehicle_count > 0
  AND (CASE WHEN household_demographics.hd_vehicle_count > 0 THEN household_demographics.hd_dep_count / household_demographics.hd_vehicle_count ELSE NULL END) > 1
  AND date_dim.d_year IN (1999, 1999+1, 1999+2)
  AND store.s_county IN ('Williamson County', 'Ziebach County', 'Walker County', 'Fairfield County')
  GROUP BY ss_ticket_number, ss_customer_sk
) dn, TPCDS_1000GB.CUSTOMER
WHERE ss_customer_sk = c_customer_sk AND cnt BETWEEN 1 AND 5
ORDER BY cnt DESC, c_last_name ASC;

-- Q74: Customer Year Balance
WITH year_total AS (
  SELECT c_customer_id customer_id, c_first_name customer_first_name, c_last_name customer_last_name, d_year AS yr,
    SUM(ss_net_paid) year_total, 's' sale_type
  FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
  WHERE c_customer_sk = ss_customer_sk AND ss_sold_date_sk = d_date_sk AND d_year IN (2001, 2001+1)
  GROUP BY c_customer_id, c_first_name, c_last_name, d_year
  UNION ALL
  SELECT c_customer_id customer_id, c_first_name customer_first_name, c_last_name customer_last_name, d_year AS yr,
    SUM(ws_net_paid) year_total, 'w' sale_type
  FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM
  WHERE c_customer_sk = ws_bill_customer_sk AND ws_sold_date_sk = d_date_sk AND d_year IN (2001, 2001+1)
  GROUP BY c_customer_id, c_first_name, c_last_name, d_year
)
SELECT t_s_secyear.customer_id, t_s_secyear.customer_first_name, t_s_secyear.customer_last_name
FROM year_total t_s_firstyear, year_total t_s_secyear, year_total t_w_firstyear, year_total t_w_secyear
WHERE t_s_secyear.customer_id = t_s_firstyear.customer_id AND t_s_firstyear.customer_id = t_w_secyear.customer_id AND t_s_firstyear.customer_id = t_w_firstyear.customer_id
AND t_s_firstyear.sale_type = 's' AND t_w_firstyear.sale_type = 'w' AND t_s_secyear.sale_type = 's' AND t_w_secyear.sale_type = 'w'
AND t_s_firstyear.yr = 2001 AND t_s_secyear.yr = 2001+1 AND t_w_firstyear.yr = 2001 AND t_w_secyear.yr = 2001+1
AND t_s_firstyear.year_total > 0 AND t_w_firstyear.year_total > 0
AND CASE WHEN t_w_firstyear.year_total > 0 THEN t_w_secyear.year_total / t_w_firstyear.year_total ELSE NULL END > CASE WHEN t_s_firstyear.year_total > 0 THEN t_s_secyear.year_total / t_s_firstyear.year_total ELSE NULL END
ORDER BY t_s_secyear.customer_id, t_s_secyear.customer_first_name, t_s_secyear.customer_last_name LIMIT 100;

-- Q75: Multi-Channel Returns YoY
WITH all_sales AS (
  SELECT d_year, i_brand_id, i_class_id, i_category_id, i_manufact_id, SUM(sales_cnt) AS sales_cnt, SUM(sales_amt) AS sales_amt
  FROM (
    SELECT d_year, i_brand_id, i_class_id, i_category_id, i_manufact_id, cs_quantity - COALESCE(cr_return_quantity, 0) AS sales_cnt, cs_ext_sales_price - COALESCE(cr_return_amount, 0) AS sales_amt
    FROM TPCDS_1000GB.CATALOG_SALES JOIN TPCDS_1000GB.ITEM ON i_item_sk = cs_item_sk JOIN TPCDS_1000GB.DATE_DIM ON d_date_sk = cs_sold_date_sk LEFT JOIN TPCDS_1000GB.CATALOG_RETURNS ON cs_order_number = cr_order_number AND cs_item_sk = cr_item_sk
    WHERE i_category = 'Books'
    UNION ALL
    SELECT d_year, i_brand_id, i_class_id, i_category_id, i_manufact_id, ss_quantity - COALESCE(sr_return_quantity, 0) AS sales_cnt, ss_ext_sales_price - COALESCE(sr_return_amt, 0) AS sales_amt
    FROM TPCDS_1000GB.STORE_SALES JOIN TPCDS_1000GB.ITEM ON i_item_sk = ss_item_sk JOIN TPCDS_1000GB.DATE_DIM ON d_date_sk = ss_sold_date_sk LEFT JOIN TPCDS_1000GB.STORE_RETURNS ON ss_ticket_number = sr_ticket_number AND ss_item_sk = sr_item_sk
    WHERE i_category = 'Books'
    UNION ALL
    SELECT d_year, i_brand_id, i_class_id, i_category_id, i_manufact_id, ws_quantity - COALESCE(wr_return_quantity, 0) AS sales_cnt, ws_ext_sales_price - COALESCE(wr_return_amt, 0) AS sales_amt
    FROM TPCDS_1000GB.WEB_SALES JOIN TPCDS_1000GB.ITEM ON i_item_sk = ws_item_sk JOIN TPCDS_1000GB.DATE_DIM ON d_date_sk = ws_sold_date_sk LEFT JOIN TPCDS_1000GB.WEB_RETURNS ON ws_order_number = wr_order_number AND ws_item_sk = wr_item_sk
    WHERE i_category = 'Books'
  ) sales_detail
  GROUP BY d_year, i_brand_id, i_class_id, i_category_id, i_manufact_id
)
SELECT prev_yr.d_year AS prev_year, curr_yr.d_year AS curr_year, curr_yr.i_brand_id, curr_yr.i_class_id, curr_yr.i_category_id, curr_yr.i_manufact_id,
  prev_yr.sales_cnt AS prev_yr_cnt, curr_yr.sales_cnt AS curr_yr_cnt, curr_yr.sales_cnt - prev_yr.sales_cnt AS sales_cnt_diff, curr_yr.sales_amt - prev_yr.sales_amt AS sales_amt_diff
FROM all_sales curr_yr, all_sales prev_yr
WHERE curr_yr.i_brand_id = prev_yr.i_brand_id AND curr_yr.i_class_id = prev_yr.i_class_id AND curr_yr.i_category_id = prev_yr.i_category_id AND curr_yr.i_manufact_id = prev_yr.i_manufact_id
AND curr_yr.d_year = 2002 AND prev_yr.d_year = 2002-1
AND CAST(curr_yr.sales_cnt AS DECIMAL(17,2)) / CAST(prev_yr.sales_cnt AS DECIMAL(17,2)) < 0.9
ORDER BY sales_cnt_diff LIMIT 100;

-- Q76: Channel Revenue by Type
SELECT channel, col_name, d_year, d_qoy, i_category, COUNT(*) sales_cnt, SUM(ext_sales_price) sales_amt
FROM (
  SELECT 'store' AS channel, 'ss_store_sk' col_name, d_year, d_qoy, i_category, ss_ext_sales_price ext_sales_price
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE ss_store_sk IS NULL AND ss_sold_date_sk = d_date_sk AND ss_item_sk = i_item_sk
  UNION ALL
  SELECT 'web' AS channel, 'ws_ship_customer_sk' col_name, d_year, d_qoy, i_category, ws_ext_sales_price ext_sales_price
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE ws_ship_customer_sk IS NULL AND ws_sold_date_sk = d_date_sk AND ws_item_sk = i_item_sk
  UNION ALL
  SELECT 'catalog' AS channel, 'cs_ship_addr_sk' col_name, d_year, d_qoy, i_category, cs_ext_sales_price ext_sales_price
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE cs_ship_addr_sk IS NULL AND cs_sold_date_sk = d_date_sk AND cs_item_sk = i_item_sk
) foo
GROUP BY channel, col_name, d_year, d_qoy, i_category
ORDER BY channel, col_name, d_year, d_qoy, i_category LIMIT 100;

-- Q77: Multi-Channel Profit
WITH ss AS (
  SELECT s_store_sk, SUM(ss_ext_sales_price) AS sales, SUM(ss_net_profit) AS profit
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND ss_store_sk = s_store_sk
  GROUP BY s_store_sk
),
sr AS (
  SELECT s_store_sk, SUM(sr_return_amt) AS returns_amt, SUM(sr_net_loss) AS profit_loss
  FROM TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE sr_returned_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND sr_store_sk = s_store_sk
  GROUP BY s_store_sk
),
csales AS (
  SELECT cs_call_center_sk, SUM(cs_ext_sales_price) AS sales, SUM(cs_net_profit) AS profit
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM
  WHERE cs_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY
  GROUP BY cs_call_center_sk
),
cret AS (
  SELECT cr_call_center_sk, SUM(cr_return_amount) AS returns_amt, SUM(cr_net_loss) AS profit_loss
  FROM TPCDS_1000GB.CATALOG_RETURNS, TPCDS_1000GB.DATE_DIM
  WHERE cr_returned_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY
  GROUP BY cr_call_center_sk
),
ws AS (
  SELECT wp_web_page_sk, SUM(ws_ext_sales_price) AS sales, SUM(ws_net_profit) AS profit
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.WEB_PAGE
  WHERE ws_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND ws_web_page_sk = wp_web_page_sk
  GROUP BY wp_web_page_sk
),
wr AS (
  SELECT wp_web_page_sk, SUM(wr_return_amt) AS returns_amt, SUM(wr_net_loss) AS profit_loss
  FROM TPCDS_1000GB.WEB_RETURNS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.WEB_PAGE
  WHERE wr_returned_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND wr_web_page_sk = wp_web_page_sk
  GROUP BY wp_web_page_sk
)
SELECT channel, id, SUM(sales) AS sales, SUM(returns_amt) AS returns_amt, SUM(profit) AS profit
FROM (
  SELECT 'store channel' AS channel, ss.s_store_sk AS id, sales, COALESCE(returns_amt, 0) AS returns_amt, (profit - COALESCE(profit_loss, 0)) AS profit FROM ss LEFT JOIN sr ON ss.s_store_sk = sr.s_store_sk
  UNION ALL
  SELECT 'catalog channel' AS channel, cs_call_center_sk AS id, sales, COALESCE(returns_amt, 0) AS returns_amt, (profit - COALESCE(profit_loss, 0)) AS profit FROM csales LEFT JOIN cret ON csales.cs_call_center_sk = cret.cr_call_center_sk
  UNION ALL
  SELECT 'web channel' AS channel, ws.wp_web_page_sk AS id, sales, COALESCE(returns_amt, 0) AS returns_amt, (profit - COALESCE(profit_loss, 0)) AS profit FROM ws LEFT JOIN wr ON ws.wp_web_page_sk = wr.wp_web_page_sk
) x
GROUP BY ROLLUP(channel, id)
ORDER BY channel, id LIMIT 100;

-- Q78: Cross Channel Revenue
WITH ws AS (
  SELECT d_year AS ws_sold_year, ws_item_sk,
    ws_bill_customer_sk ws_customer_sk,
    SUM(ws_quantity) ws_qty, SUM(ws_wholesale_cost) ws_wc, SUM(ws_sales_price) ws_sp
  FROM TPCDS_1000GB.WEB_SALES LEFT JOIN TPCDS_1000GB.WEB_RETURNS ON wr_order_number = ws_order_number AND ws_item_sk = wr_item_sk
    JOIN TPCDS_1000GB.DATE_DIM ON ws_sold_date_sk = d_date_sk
  WHERE wr_order_number IS NULL
  GROUP BY d_year, ws_item_sk, ws_bill_customer_sk
),
csales AS (
  SELECT d_year AS cs_sold_year, cs_item_sk,
    cs_bill_customer_sk cs_customer_sk,
    SUM(cs_quantity) cs_qty, SUM(cs_wholesale_cost) cs_wc, SUM(cs_sales_price) cs_sp
  FROM TPCDS_1000GB.CATALOG_SALES LEFT JOIN TPCDS_1000GB.CATALOG_RETURNS ON cr_order_number = cs_order_number AND cs_item_sk = cr_item_sk
    JOIN TPCDS_1000GB.DATE_DIM ON cs_sold_date_sk = d_date_sk
  WHERE cr_order_number IS NULL
  GROUP BY d_year, cs_item_sk, cs_bill_customer_sk
),
ss AS (
  SELECT d_year AS ss_sold_year, ss_item_sk,
    ss_customer_sk,
    SUM(ss_quantity) ss_qty, SUM(ss_wholesale_cost) ss_wc, SUM(ss_sales_price) ss_sp
  FROM TPCDS_1000GB.STORE_SALES LEFT JOIN TPCDS_1000GB.STORE_RETURNS ON sr_ticket_number = ss_ticket_number AND ss_item_sk = sr_item_sk
    JOIN TPCDS_1000GB.DATE_DIM ON ss_sold_date_sk = d_date_sk
  WHERE sr_ticket_number IS NULL
  GROUP BY d_year, ss_item_sk, ss_customer_sk
)
SELECT ss_sold_year, ss_item_sk, ss_customer_sk,
  ROUND(ss_qty / (COALESCE(ws_qty, 0) + COALESCE(cs_qty, 0)), 2) AS ratio,
  ss_qty store_qty, ss_wc store_wholesale_cost, ss_sp store_sales_price,
  COALESCE(ws_qty, 0) + COALESCE(cs_qty, 0) other_chan_qty,
  COALESCE(ws_wc, 0) + COALESCE(cs_wc, 0) other_chan_wholesale_cost,
  COALESCE(ws_sp, 0) + COALESCE(cs_sp, 0) other_chan_sales_price
FROM ss
  LEFT JOIN ws ON ws_sold_year = ss_sold_year AND ws_item_sk = ss_item_sk AND ws_customer_sk = ss_customer_sk
  LEFT JOIN csales ON cs_sold_year = ss_sold_year AND cs_item_sk = ss_item_sk AND cs_customer_sk = ss_customer_sk
WHERE (COALESCE(ws_qty, 0) > 0 OR COALESCE(cs_qty, 0) > 0) AND ss_sold_year = 2000
ORDER BY ss_sold_year, ss_item_sk, ss_customer_sk, ss_qty DESC, ss_wc DESC, ss_sp DESC,
  other_chan_qty, other_chan_wholesale_cost, other_chan_sales_price, ratio
LIMIT 100;

-- Q79: Store Sales Customer Annual
SELECT c_last_name, c_first_name, SUBSTR(s_city, 1, 30) city, ss_ticket_number, amt, profit
FROM (
  SELECT ss_ticket_number, ss_customer_sk, store.s_city, SUM(ss_coupon_amt) amt, SUM(ss_net_profit) profit
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS
  WHERE store_sales.ss_sold_date_sk = date_dim.d_date_sk AND store_sales.ss_store_sk = store.s_store_sk AND store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
  AND (household_demographics.hd_dep_count = 6 OR household_demographics.hd_vehicle_count > 2) AND date_dim.d_dow = 1 AND date_dim.d_year IN (1999, 1999+1, 1999+2)
  AND store.s_number_employees BETWEEN 200 AND 295
  GROUP BY ss_ticket_number, ss_customer_sk, ss_addr_sk, store.s_city
) ms, TPCDS_1000GB.CUSTOMER
WHERE ss_customer_sk = c_customer_sk
ORDER BY c_last_name, c_first_name, city, profit LIMIT 100;

-- Q80: Multi-Channel Net Profit
WITH ssr AS (
  SELECT s_store_id AS store_id, SUM(ss_ext_sales_price) AS sales, SUM(COALESCE(sr_return_amt, 0)) AS returns_val, SUM(ss_net_profit - COALESCE(sr_net_loss, 0)) AS profit
  FROM TPCDS_1000GB.STORE_SALES LEFT OUTER JOIN TPCDS_1000GB.STORE_RETURNS ON ss_item_sk = sr_item_sk AND ss_ticket_number = sr_ticket_number,
    TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE, TPCDS_1000GB.ITEM, TPCDS_1000GB.PROMOTION
  WHERE ss_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND ss_store_sk = s_store_sk AND ss_item_sk = i_item_sk AND i_current_price > 50 AND ss_promo_sk = p_promo_sk AND p_channel_tv = 'N'
  GROUP BY s_store_id
),
csr AS (
  SELECT cp_catalog_page_id AS catalog_page_id, SUM(cs_ext_sales_price) AS sales, SUM(COALESCE(cr_return_amount, 0)) AS returns_val, SUM(cs_net_profit - COALESCE(cr_net_loss, 0)) AS profit
  FROM TPCDS_1000GB.CATALOG_SALES LEFT OUTER JOIN TPCDS_1000GB.CATALOG_RETURNS ON cs_item_sk = cr_item_sk AND cs_order_number = cr_order_number,
    TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CATALOG_PAGE, TPCDS_1000GB.ITEM, TPCDS_1000GB.PROMOTION
  WHERE cs_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND cs_catalog_page_sk = cp_catalog_page_sk AND cs_item_sk = i_item_sk AND i_current_price > 50 AND cs_promo_sk = p_promo_sk AND p_channel_tv = 'N'
  GROUP BY cp_catalog_page_id
),
wsr AS (
  SELECT web_site_id, SUM(ws_ext_sales_price) AS sales, SUM(COALESCE(wr_return_amt, 0)) AS returns_val, SUM(ws_net_profit - COALESCE(wr_net_loss, 0)) AS profit
  FROM TPCDS_1000GB.WEB_SALES LEFT OUTER JOIN TPCDS_1000GB.WEB_RETURNS ON ws_item_sk = wr_item_sk AND ws_order_number = wr_order_number,
    TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.WEB_SITE, TPCDS_1000GB.ITEM, TPCDS_1000GB.PROMOTION
  WHERE ws_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '2000-08-23' AND DATE '2000-08-23' + INTERVAL '30' DAY AND ws_web_site_sk = web_site_sk AND ws_item_sk = i_item_sk AND i_current_price > 50 AND ws_promo_sk = p_promo_sk AND p_channel_tv = 'N'
  GROUP BY web_site_id
)
SELECT channel, id, SUM(sales) AS sales, SUM(returns_val) AS returns_val, SUM(profit) AS profit
FROM (
  SELECT 'store channel' AS channel, CONCAT('store', store_id) AS id, sales, returns_val, profit FROM ssr
  UNION ALL
  SELECT 'catalog channel' AS channel, CONCAT('catalog_page', catalog_page_id) AS id, sales, returns_val, profit FROM csr
  UNION ALL
  SELECT 'web channel' AS channel, CONCAT('web_site', web_site_id) AS id, sales, returns_val, profit FROM wsr
) x
GROUP BY ROLLUP(channel, id)
ORDER BY channel, id LIMIT 100;

-- Q81: Catalog Returns by State
WITH customer_total_return AS (
  SELECT cr_returning_customer_sk AS ctr_customer_sk, ca_state AS ctr_state, SUM(cr_return_amt_inc_tax) AS ctr_total_return
  FROM TPCDS_1000GB.CATALOG_RETURNS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS
  WHERE cr_returned_date_sk = d_date_sk AND d_year = 2000 AND cr_returning_addr_sk = ca_address_sk
  GROUP BY cr_returning_customer_sk, ca_state
)
SELECT c_customer_id, c_salutation, c_first_name, c_last_name, ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_county, ca_state, ca_zip, ca_country, ca_gmt_offset, ca_location_type, ctr_total_return
FROM customer_total_return ctr1, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.CUSTOMER
WHERE ctr1.ctr_total_return > (SELECT AVG(ctr_total_return) * 1.2 FROM customer_total_return ctr2 WHERE ctr1.ctr_state = ctr2.ctr_state)
AND ca_address_sk = c_current_addr_sk AND ca_state = 'GA' AND ctr1.ctr_customer_sk = c_customer_sk
ORDER BY c_customer_id, c_salutation, c_first_name, c_last_name, ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_county, ca_state, ca_zip, ca_country, ca_gmt_offset, ca_location_type, ctr_total_return
LIMIT 100;

-- Q82: Item Inventory Price
SELECT i_item_id, i_item_desc, i_current_price
FROM TPCDS_1000GB.ITEM, TPCDS_1000GB.INVENTORY, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE_SALES
WHERE i_current_price BETWEEN 62 AND 62+30 AND inv_item_sk = i_item_sk AND d_date_sk = inv_date_sk
AND d_date BETWEEN DATE '2000-05-25' AND DATE '2000-05-25' + INTERVAL '60' DAY AND i_manufact_id IN (129, 270, 821, 423)
AND inv_quantity_on_hand BETWEEN 100 AND 500 AND ss_item_sk = i_item_sk
GROUP BY i_item_id, i_item_desc, i_current_price
ORDER BY i_item_id LIMIT 100;

-- Q83: Returns by Item Date
WITH sr_items AS (
  SELECT i_item_id item_id, SUM(sr_return_quantity) sr_item_qty
  FROM TPCDS_1000GB.STORE_RETURNS, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE sr_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1000GB.DATE_DIM WHERE d_week_seq IN (SELECT d_week_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_date IN (DATE '2000-06-30', DATE '2000-09-27', DATE '2000-11-17')))
  AND sr_returned_date_sk = d_date_sk
  GROUP BY i_item_id
),
cr_items AS (
  SELECT i_item_id item_id, SUM(cr_return_quantity) cr_item_qty
  FROM TPCDS_1000GB.CATALOG_RETURNS, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE cr_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1000GB.DATE_DIM WHERE d_week_seq IN (SELECT d_week_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_date IN (DATE '2000-06-30', DATE '2000-09-27', DATE '2000-11-17')))
  AND cr_returned_date_sk = d_date_sk
  GROUP BY i_item_id
),
wr_items AS (
  SELECT i_item_id item_id, SUM(wr_return_quantity) wr_item_qty
  FROM TPCDS_1000GB.WEB_RETURNS, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
  WHERE wr_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1000GB.DATE_DIM WHERE d_week_seq IN (SELECT d_week_seq FROM TPCDS_1000GB.DATE_DIM WHERE d_date IN (DATE '2000-06-30', DATE '2000-09-27', DATE '2000-11-17')))
  AND wr_returned_date_sk = d_date_sk
  GROUP BY i_item_id
)
SELECT sr_items.item_id, sr_item_qty, sr_item_qty / (sr_item_qty + cr_item_qty + wr_item_qty) / 3.0 * 100 sr_dev,
  cr_item_qty, cr_item_qty / (sr_item_qty + cr_item_qty + wr_item_qty) / 3.0 * 100 cr_dev,
  wr_item_qty, wr_item_qty / (sr_item_qty + cr_item_qty + wr_item_qty) / 3.0 * 100 wr_dev,
  (sr_item_qty + cr_item_qty + wr_item_qty) / 3.0 average
FROM sr_items, cr_items, wr_items
WHERE sr_items.item_id = cr_items.item_id AND sr_items.item_id = wr_items.item_id
ORDER BY sr_items.item_id, sr_item_qty LIMIT 100;

-- Q84: Customer Income Demographics
SELECT c_customer_id AS customer_id, COALESCE(c_last_name, '') || ', ' || COALESCE(c_first_name, '') AS customername
FROM TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.INCOME_BAND, TPCDS_1000GB.STORE_RETURNS
WHERE ca_city = 'Edgewood' AND c_current_addr_sk = ca_address_sk AND ib_lower_bound >= 38128 AND ib_upper_bound <= 38128+50000
AND ib_income_band_sk = hd_income_band_sk AND cd_demo_sk = c_current_cdemo_sk AND hd_demo_sk = c_current_hdemo_sk AND sr_cdemo_sk = cd_demo_sk
ORDER BY c_customer_id LIMIT 100;

-- Q85: Web Returns Reason Analysis
SELECT SUBSTR(r_reason_desc, 1, 20) reason_desc, AVG(ws_quantity) avg_qty, AVG(wr_refunded_cash) avg_refund, AVG(wr_fee) avg_fee
FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.WEB_RETURNS, TPCDS_1000GB.WEB_PAGE, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS cd1, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS cd2,
  TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.REASON
WHERE ws_web_page_sk = wp_web_page_sk AND ws_item_sk = wr_item_sk AND ws_order_number = wr_order_number AND ws_sold_date_sk = d_date_sk AND d_year = 2000
AND cd1.cd_demo_sk = wr_refunded_cdemo_sk AND cd2.cd_demo_sk = wr_returning_cdemo_sk AND ca_address_sk = wr_refunded_addr_sk AND r_reason_sk = wr_reason_sk
AND (
  (cd1.cd_marital_status = 'M' AND cd1.cd_marital_status = cd2.cd_marital_status AND cd1.cd_education_status = 'Advanced Degree' AND cd1.cd_education_status = cd2.cd_education_status AND ws_sales_price BETWEEN 100.00 AND 150.00)
  OR (cd1.cd_marital_status = 'S' AND cd1.cd_marital_status = cd2.cd_marital_status AND cd1.cd_education_status = 'College' AND cd1.cd_education_status = cd2.cd_education_status AND ws_sales_price BETWEEN 50.00 AND 100.00)
  OR (cd1.cd_marital_status = 'W' AND cd1.cd_marital_status = cd2.cd_marital_status AND cd1.cd_education_status = '2 yr Degree' AND cd1.cd_education_status = cd2.cd_education_status AND ws_sales_price BETWEEN 150.00 AND 200.00)
)
AND (
  (ca_country = 'United States' AND ca_state IN ('IN', 'OH', 'NJ') AND ws_net_profit BETWEEN 100 AND 200)
  OR (ca_country = 'United States' AND ca_state IN ('WI', 'CT', 'KY') AND ws_net_profit BETWEEN 150 AND 300)
  OR (ca_country = 'United States' AND ca_state IN ('LA', 'IA', 'AR') AND ws_net_profit BETWEEN 50 AND 250)
)
GROUP BY r_reason_desc
ORDER BY reason_desc, avg_qty, avg_refund, avg_fee LIMIT 100;

-- Q86: Web Sales Rollup
SELECT SUM(ws_net_paid) AS total_sum, i_category, i_class,
  GROUPING(i_category)+GROUPING(i_class) AS lochierarchy,
  RANK() OVER (PARTITION BY GROUPING(i_category)+GROUPING(i_class), CASE WHEN GROUPING(i_class) = 0 THEN i_category END ORDER BY SUM(ws_net_paid) DESC) AS rank_within_parent
FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.ITEM
WHERE d1.d_month_seq BETWEEN 1200 AND 1200+11 AND d1.d_date_sk = ws_sold_date_sk AND i_item_sk = ws_item_sk
GROUP BY ROLLUP(i_category, i_class)
ORDER BY lochierarchy DESC, CASE WHEN lochierarchy = 0 THEN i_category END, rank_within_parent LIMIT 100;

-- Q87: Cross Channel Distinct
SELECT COUNT(*) FROM (
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER
  WHERE store_sales.ss_sold_date_sk = date_dim.d_date_sk AND store_sales.ss_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
  EXCEPT
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER
  WHERE catalog_sales.cs_sold_date_sk = date_dim.d_date_sk AND catalog_sales.cs_bill_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
  EXCEPT
  SELECT DISTINCT c_last_name, c_first_name, d_date
  FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER
  WHERE web_sales.ws_sold_date_sk = date_dim.d_date_sk AND web_sales.ws_bill_customer_sk = customer.c_customer_sk AND d_month_seq BETWEEN 1200 AND 1200+11
) cool_cust;

-- Q88: Store Sales Time Ranges
SELECT * FROM (
  SELECT COUNT(*) h8_30_to_9 FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk AND time_dim.t_hour = 8 AND time_dim.t_minute >= 30
  AND ((household_demographics.hd_dep_count = 4 AND household_demographics.hd_vehicle_count <= 4+2) OR (household_demographics.hd_dep_count = 2 AND household_demographics.hd_vehicle_count <= 2+2) OR (household_demographics.hd_dep_count = 0 AND household_demographics.hd_vehicle_count <= 0+2))
  AND store.s_store_name = 'ese'
) s1,
(SELECT COUNT(*) h9_to_9_30 FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk AND time_dim.t_hour = 9 AND time_dim.t_minute < 30
  AND ((household_demographics.hd_dep_count = 4 AND household_demographics.hd_vehicle_count <= 4+2) OR (household_demographics.hd_dep_count = 2 AND household_demographics.hd_vehicle_count <= 2+2) OR (household_demographics.hd_dep_count = 0 AND household_demographics.hd_vehicle_count <= 0+2))
  AND store.s_store_name = 'ese'
) s2,
(SELECT COUNT(*) h9_30_to_10 FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk AND time_dim.t_hour = 9 AND time_dim.t_minute >= 30
  AND ((household_demographics.hd_dep_count = 4 AND household_demographics.hd_vehicle_count <= 4+2) OR (household_demographics.hd_dep_count = 2 AND household_demographics.hd_vehicle_count <= 2+2) OR (household_demographics.hd_dep_count = 0 AND household_demographics.hd_vehicle_count <= 0+2))
  AND store.s_store_name = 'ese'
) s3,
(SELECT COUNT(*) h10_to_10_30 FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk AND time_dim.t_hour = 10 AND time_dim.t_minute < 30
  AND ((household_demographics.hd_dep_count = 4 AND household_demographics.hd_vehicle_count <= 4+2) OR (household_demographics.hd_dep_count = 2 AND household_demographics.hd_vehicle_count <= 2+2) OR (household_demographics.hd_dep_count = 0 AND household_demographics.hd_vehicle_count <= 0+2))
  AND store.s_store_name = 'ese'
) s4,
(SELECT COUNT(*) h10_30_to_11 FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk AND time_dim.t_hour = 10 AND time_dim.t_minute >= 30
  AND ((household_demographics.hd_dep_count = 4 AND household_demographics.hd_vehicle_count <= 4+2) OR (household_demographics.hd_dep_count = 2 AND household_demographics.hd_vehicle_count <= 2+2) OR (household_demographics.hd_dep_count = 0 AND household_demographics.hd_vehicle_count <= 0+2))
  AND store.s_store_name = 'ese'
) s5,
(SELECT COUNT(*) h11_to_11_30 FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk AND time_dim.t_hour = 11 AND time_dim.t_minute < 30
  AND ((household_demographics.hd_dep_count = 4 AND household_demographics.hd_vehicle_count <= 4+2) OR (household_demographics.hd_dep_count = 2 AND household_demographics.hd_vehicle_count <= 2+2) OR (household_demographics.hd_dep_count = 0 AND household_demographics.hd_vehicle_count <= 0+2))
  AND store.s_store_name = 'ese'
) s6,
(SELECT COUNT(*) h11_30_to_12 FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk AND time_dim.t_hour = 11 AND time_dim.t_minute >= 30
  AND ((household_demographics.hd_dep_count = 4 AND household_demographics.hd_vehicle_count <= 4+2) OR (household_demographics.hd_dep_count = 2 AND household_demographics.hd_vehicle_count <= 2+2) OR (household_demographics.hd_dep_count = 0 AND household_demographics.hd_vehicle_count <= 0+2))
  AND store.s_store_name = 'ese'
) s7,
(SELECT COUNT(*) h12_to_12_30 FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
  WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk AND time_dim.t_hour = 12 AND time_dim.t_minute < 30
  AND ((household_demographics.hd_dep_count = 4 AND household_demographics.hd_vehicle_count <= 4+2) OR (household_demographics.hd_dep_count = 2 AND household_demographics.hd_vehicle_count <= 2+2) OR (household_demographics.hd_dep_count = 0 AND household_demographics.hd_vehicle_count <= 0+2))
  AND store.s_store_name = 'ese'
) s8;

-- Q89: Monthly Store Sales Deviation
SELECT * FROM (
  SELECT i_category, i_class, i_brand, s_store_name, s_company_name, d_moy,
    SUM(ss_sales_price) sum_sales,
    AVG(SUM(ss_sales_price)) OVER (PARTITION BY i_category, i_brand, s_store_name, s_company_name) avg_monthly_sales
  FROM TPCDS_1000GB.ITEM, TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.STORE
  WHERE ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk AND ss_store_sk = s_store_sk AND d_year = 1999
  AND ((i_category IN ('Children', 'Music', 'Home') AND i_class IN ('toddlers', 'pop', 'lighting'))
    OR (i_category IN ('Jewelry', 'Books', 'Sports') AND i_class IN ('costume', 'travel', 'football')))
  GROUP BY i_category, i_class, i_brand, s_store_name, s_company_name, d_moy
) tmp1
WHERE CASE WHEN avg_monthly_sales <> 0 THEN ABS(sum_sales - avg_monthly_sales) / avg_monthly_sales ELSE NULL END > 0.1
ORDER BY sum_sales - avg_monthly_sales, s_store_name LIMIT 100;

-- Q90: Web Sales Time Ratio
SELECT CAST(amc AS DECIMAL(15,4)) / CAST(pmc AS DECIMAL(15,4)) am_pm_ratio
FROM (SELECT COUNT(*) amc FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.WEB_PAGE
  WHERE ws_sold_time_sk = time_dim.t_time_sk AND ws_ship_hdemo_sk = household_demographics.hd_demo_sk AND ws_web_page_sk = web_page.wp_web_page_sk
  AND time_dim.t_hour BETWEEN 8 AND 8+1 AND household_demographics.hd_dep_count = 6 AND web_page.wp_char_count BETWEEN 5000 AND 5200
) at_val,
(SELECT COUNT(*) pmc FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.WEB_PAGE
  WHERE ws_sold_time_sk = time_dim.t_time_sk AND ws_ship_hdemo_sk = household_demographics.hd_demo_sk AND ws_web_page_sk = web_page.wp_web_page_sk
  AND time_dim.t_hour BETWEEN 19 AND 19+1 AND household_demographics.hd_dep_count = 6 AND web_page.wp_char_count BETWEEN 5000 AND 5200
) pt_val
ORDER BY am_pm_ratio LIMIT 100;

-- Q91: Call Center Web Returns
SELECT cc_call_center_id Call_Center, cc_name Call_Center_Name, cc_manager Manager,
  SUM(cr_net_loss) Returns_Loss
FROM TPCDS_1000GB.CALL_CENTER, TPCDS_1000GB.CATALOG_RETURNS, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.CUSTOMER_DEMOGRAPHICS, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS
WHERE cr_call_center_sk = cc_call_center_sk AND cr_returned_date_sk = d_date_sk AND cr_returning_customer_sk = c_customer_sk AND cd_demo_sk = c_current_cdemo_sk AND hd_demo_sk = c_current_hdemo_sk AND ca_address_sk = c_current_addr_sk
AND d_year = 1998 AND d_moy = 11 AND (cd_marital_status = 'M' OR cd_marital_status = 'W') AND (cd_education_status = 'Unknown' OR cd_education_status = 'Advanced Degree') AND ca_gmt_offset = -7 AND hd_buy_potential LIKE 'Unknown%'
GROUP BY cc_call_center_id, cc_name, cc_manager, cd_marital_status, cd_education_status
ORDER BY SUM(cr_net_loss) DESC;

-- Q92: Web Sales Excess Discount
SELECT SUM(ws_ext_discount_amt) AS excess_discount_amount
FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
WHERE i_manufact_id = 350 AND i_item_sk = ws_item_sk
AND d_date BETWEEN DATE '2000-01-27' AND DATE '2000-01-27' + INTERVAL '90' DAY AND d_date_sk = ws_sold_date_sk
AND ws_ext_discount_amt > (
  SELECT 1.3 * AVG(ws_ext_discount_amt) FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.DATE_DIM
  WHERE ws_item_sk = i_item_sk AND d_date BETWEEN DATE '2000-01-27' AND DATE '2000-01-27' + INTERVAL '90' DAY AND d_date_sk = ws_sold_date_sk
)
ORDER BY SUM(ws_ext_discount_amt) LIMIT 100;

-- Q93: Store Sales Returns Reason
SELECT ss_customer_sk, SUM(act_sales) sumsales
FROM (
  SELECT ss_item_sk, ss_ticket_number, ss_customer_sk,
    CASE WHEN sr_return_quantity IS NOT NULL THEN (ss_quantity - sr_return_quantity) * ss_sales_price ELSE ss_quantity * ss_sales_price END act_sales
  FROM TPCDS_1000GB.STORE_SALES LEFT OUTER JOIN TPCDS_1000GB.STORE_RETURNS ON sr_item_sk = ss_item_sk AND sr_ticket_number = ss_ticket_number,
    TPCDS_1000GB.REASON
  WHERE sr_reason_sk = r_reason_sk AND r_reason_desc = 'reason 28'
) t
GROUP BY ss_customer_sk
ORDER BY sumsales, ss_customer_sk LIMIT 100;

-- Q94: Web Sales Unique Orders
SELECT COUNT(DISTINCT ws_order_number) AS order_count, SUM(ws_ext_ship_cost) AS total_shipping_cost, SUM(ws_net_profit) AS total_net_profit
FROM TPCDS_1000GB.WEB_SALES ws1, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.WEB_SITE
WHERE d_date BETWEEN DATE '1999-02-01' AND DATE '1999-02-01' + INTERVAL '60' DAY
AND ws1.ws_ship_date_sk = d_date_sk AND ws1.ws_ship_addr_sk = ca_address_sk AND ca_state = 'IL'
AND ws1.ws_web_site_sk = web_site_sk AND web_company_name = 'pri'
AND EXISTS (SELECT * FROM TPCDS_1000GB.WEB_SALES ws2 WHERE ws1.ws_order_number = ws2.ws_order_number AND ws1.ws_warehouse_sk <> ws2.ws_warehouse_sk)
AND NOT EXISTS (SELECT * FROM TPCDS_1000GB.WEB_RETURNS wr1 WHERE ws1.ws_order_number = wr1.wr_order_number)
ORDER BY order_count LIMIT 100;

-- Q95: Web Sales Unique Large Orders
WITH ws_wh AS (
  SELECT ws1.ws_order_number, ws1.ws_warehouse_sk wh1, ws2.ws_warehouse_sk wh2
  FROM TPCDS_1000GB.WEB_SALES ws1, TPCDS_1000GB.WEB_SALES ws2
  WHERE ws1.ws_order_number = ws2.ws_order_number AND ws1.ws_warehouse_sk <> ws2.ws_warehouse_sk
)
SELECT COUNT(DISTINCT ws_order_number) AS order_count, SUM(ws_ext_ship_cost) AS total_shipping_cost, SUM(ws_net_profit) AS total_net_profit
FROM TPCDS_1000GB.WEB_SALES ws1, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.CUSTOMER_ADDRESS, TPCDS_1000GB.WEB_SITE
WHERE d_date BETWEEN DATE '1999-02-01' AND DATE '1999-02-01' + INTERVAL '60' DAY
AND ws1.ws_ship_date_sk = d_date_sk AND ws1.ws_ship_addr_sk = ca_address_sk AND ca_state = 'IL'
AND ws1.ws_web_site_sk = web_site_sk AND web_company_name = 'pri'
AND ws1.ws_order_number IN (SELECT ws_order_number FROM ws_wh)
AND ws1.ws_order_number IN (SELECT wr_order_number FROM TPCDS_1000GB.WEB_RETURNS, ws_wh WHERE wr_order_number = ws_wh.ws_order_number)
ORDER BY order_count LIMIT 100;

-- Q96: Store Sales Count Time
SELECT COUNT(*)
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.HOUSEHOLD_DEMOGRAPHICS, TPCDS_1000GB.TIME_DIM, TPCDS_1000GB.STORE
WHERE ss_sold_time_sk = time_dim.t_time_sk AND ss_hdemo_sk = household_demographics.hd_demo_sk AND ss_store_sk = s_store_sk
AND time_dim.t_hour = 20 AND time_dim.t_minute >= 30 AND household_demographics.hd_dep_count = 7
AND store.s_store_name = 'ese'
ORDER BY COUNT(*) LIMIT 100;

-- Q97: Store Catalog Distinct
WITH ssci AS (
  SELECT ss_customer_sk customer_sk, ss_item_sk item_sk
  FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM
  WHERE ss_sold_date_sk = d_date_sk AND d_month_seq BETWEEN 1200 AND 1200+11
  GROUP BY ss_customer_sk, ss_item_sk
),
csci AS (
  SELECT cs_bill_customer_sk customer_sk, cs_item_sk item_sk
  FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.DATE_DIM
  WHERE cs_sold_date_sk = d_date_sk AND d_month_seq BETWEEN 1200 AND 1200+11
  GROUP BY cs_bill_customer_sk, cs_item_sk
)
SELECT SUM(CASE WHEN ssci.customer_sk IS NOT NULL AND csci.customer_sk IS NULL THEN 1 ELSE 0 END) store_only,
  SUM(CASE WHEN ssci.customer_sk IS NULL AND csci.customer_sk IS NOT NULL THEN 1 ELSE 0 END) catalog_only,
  SUM(CASE WHEN ssci.customer_sk IS NOT NULL AND csci.customer_sk IS NOT NULL THEN 1 ELSE 0 END) store_and_catalog
FROM ssci FULL OUTER JOIN csci ON ssci.customer_sk = csci.customer_sk AND ssci.item_sk = csci.item_sk
LIMIT 100;

-- Q98: Item Sales Repartition
SELECT i_item_id, i_item_desc, i_category, i_class, i_current_price,
  SUM(ss_ext_sales_price) AS itemrevenue,
  SUM(ss_ext_sales_price)*100/SUM(SUM(ss_ext_sales_price)) OVER (PARTITION BY i_class) AS revenueratio
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
WHERE ss_item_sk = i_item_sk AND i_category IN ('Sports', 'Books', 'Home')
AND ss_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '1999-02-22' AND DATE '1999-02-22' + INTERVAL '30' DAY
GROUP BY i_item_id, i_item_desc, i_category, i_class, i_current_price
ORDER BY i_category, i_class, i_item_id, i_item_desc, revenueratio;

-- Q99: Catalog Ship Mode Warehouse
SELECT SUBSTR(w_warehouse_name, 1, 20) wh_name, sm_type, cc_name,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk <= 30 THEN 1 ELSE 0 END) AS days_30,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk > 30 AND cs_ship_date_sk - cs_sold_date_sk <= 60 THEN 1 ELSE 0 END) AS days_31_60,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk > 60 AND cs_ship_date_sk - cs_sold_date_sk <= 90 THEN 1 ELSE 0 END) AS days_61_90,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk > 90 AND cs_ship_date_sk - cs_sold_date_sk <= 120 THEN 1 ELSE 0 END) AS days_91_120,
  SUM(CASE WHEN cs_ship_date_sk - cs_sold_date_sk > 120 THEN 1 ELSE 0 END) AS days_gt120
FROM TPCDS_1000GB.CATALOG_SALES, TPCDS_1000GB.WAREHOUSE, TPCDS_1000GB.SHIP_MODE, TPCDS_1000GB.CALL_CENTER, TPCDS_1000GB.DATE_DIM
WHERE d_month_seq BETWEEN 1200 AND 1200+11 AND cs_ship_date_sk = d_date_sk AND cs_warehouse_sk = w_warehouse_sk AND cs_ship_mode_sk = sm_ship_mode_sk AND cs_call_center_sk = cc_call_center_sk
GROUP BY SUBSTR(w_warehouse_name, 1, 20), sm_type, cc_name
ORDER BY SUBSTR(w_warehouse_name, 1, 20), sm_type, cc_name LIMIT 100;

