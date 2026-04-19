-- Q14: Cross Channel Sales
WITH cross_items AS (
  SELECT i_item_sk ss_item_sk FROM TPCDS_10GB.ITEM,
    (SELECT iss.i_brand_id brand_id, iss.i_class_id class_id, iss.i_category_id category_id
     FROM TPCDS_10GB.STORE_SALES, TPCDS_10GB.ITEM iss, TPCDS_10GB.DATE_DIM d1
     WHERE ss_item_sk = iss.i_item_sk AND ss_sold_date_sk = d1.d_date_sk AND d1.d_year BETWEEN 1999 AND 1999+2
     INTERSECT
     SELECT ics.i_brand_id, ics.i_class_id, ics.i_category_id
     FROM TPCDS_10GB.CATALOG_SALES, TPCDS_10GB.ITEM ics, TPCDS_10GB.DATE_DIM d2
     WHERE cs_item_sk = ics.i_item_sk AND cs_sold_date_sk = d2.d_date_sk AND d2.d_year BETWEEN 1999 AND 1999+2
     INTERSECT
     SELECT iws.i_brand_id, iws.i_class_id, iws.i_category_id
     FROM TPCDS_10GB.WEB_SALES, TPCDS_10GB.ITEM iws, TPCDS_10GB.DATE_DIM d3
     WHERE ws_item_sk = iws.i_item_sk AND ws_sold_date_sk = d3.d_date_sk AND d3.d_year BETWEEN 1999 AND 1999+2) x
  WHERE i_brand_id = brand_id AND i_class_id = class_id AND i_category_id = category_id
),
avg_sales AS (
  SELECT AVG(quantity*list_price) average_sales FROM (
    SELECT ss_quantity quantity, ss_list_price list_price FROM TPCDS_10GB.STORE_SALES, TPCDS_10GB.DATE_DIM WHERE ss_sold_date_sk = d_date_sk AND d_year BETWEEN 1999 AND 1999+2
    UNION ALL
    SELECT cs_quantity quantity, cs_list_price list_price FROM TPCDS_10GB.CATALOG_SALES, TPCDS_10GB.DATE_DIM WHERE cs_sold_date_sk = d_date_sk AND d_year BETWEEN 1999 AND 1999+2
    UNION ALL
    SELECT ws_quantity quantity, ws_list_price list_price FROM TPCDS_10GB.WEB_SALES, TPCDS_10GB.DATE_DIM WHERE ws_sold_date_sk = d_date_sk AND d_year BETWEEN 1999 AND 1999+2
  ) t
)
SELECT * FROM
(SELECT 'store' channel, i_brand_id, i_class_id, i_category_id,
  SUM(ss_quantity*ss_list_price) sales, COUNT(*) number_sales
  FROM TPCDS_10GB.STORE_SALES, TPCDS_10GB.ITEM, TPCDS_10GB.DATE_DIM
  WHERE ss_item_sk IN (SELECT ss_item_sk FROM cross_items) AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk
  AND d_week_seq = (SELECT d_week_seq FROM TPCDS_10GB.DATE_DIM WHERE d_year = 1999+1 AND d_moy = 12 AND d_dom = 1)
  GROUP BY i_brand_id, i_class_id, i_category_id
  HAVING SUM(ss_quantity*ss_list_price) > (SELECT average_sales FROM avg_sales)) this_year,
(SELECT 'store' channel, i_brand_id, i_class_id, i_category_id,
  SUM(ss_quantity*ss_list_price) sales, COUNT(*) number_sales
  FROM TPCDS_10GB.STORE_SALES, TPCDS_10GB.ITEM, TPCDS_10GB.DATE_DIM
  WHERE ss_item_sk IN (SELECT ss_item_sk FROM cross_items) AND ss_item_sk = i_item_sk AND ss_sold_date_sk = d_date_sk
  AND d_week_seq = (SELECT d_week_seq FROM TPCDS_10GB.DATE_DIM WHERE d_year = 1999 AND d_moy = 12 AND d_dom = 1)
  GROUP BY i_brand_id, i_class_id, i_category_id
  HAVING SUM(ss_quantity*ss_list_price) > (SELECT average_sales FROM avg_sales)) last_year
WHERE this_year.i_brand_id = last_year.i_brand_id
  AND this_year.i_class_id = last_year.i_class_id
  AND this_year.i_category_id = last_year.i_category_id
ORDER BY this_year.channel, this_year.i_brand_id, this_year.i_class_id, this_year.i_category_id LIMIT 100;
