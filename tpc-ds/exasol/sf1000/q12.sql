-- Q12: Web Item Revenue
SELECT i_item_id, i_item_desc, i_category, i_class, i_current_price,
  SUM(ws_ext_sales_price) AS itemrevenue,
  SUM(ws_ext_sales_price)*100/SUM(SUM(ws_ext_sales_price)) OVER (PARTITION BY i_class) AS revenueratio
FROM TPCDS_1000GB.WEB_SALES, TPCDS_1000GB.ITEM, TPCDS_1000GB.DATE_DIM
WHERE ws_item_sk = i_item_sk AND i_category IN ('Sports', 'Books', 'Home')
AND ws_sold_date_sk = d_date_sk AND d_date BETWEEN DATE '1999-02-22' AND DATE '1999-02-22' + INTERVAL '30' DAY
GROUP BY i_item_id, i_item_desc, i_category, i_class, i_current_price
ORDER BY i_category, i_class, i_item_id, i_item_desc, revenueratio LIMIT 100;
