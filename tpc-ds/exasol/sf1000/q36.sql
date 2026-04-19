-- Q36: Store Sales by Hierarchy
SELECT SUM(ss_net_profit)/SUM(ss_ext_sales_price) AS gross_margin, i_category, i_class,
  GROUPING(i_category)+GROUPING(i_class) AS lochierarchy,
  RANK() OVER (PARTITION BY GROUPING(i_category)+GROUPING(i_class), CASE WHEN GROUPING(i_class) = 0 THEN i_category END ORDER BY SUM(ss_net_profit)/SUM(ss_ext_sales_price) ASC) AS rank_within_parent
FROM TPCDS_1000GB.STORE_SALES, TPCDS_1000GB.DATE_DIM d1, TPCDS_1000GB.ITEM, TPCDS_1000GB.STORE
WHERE d1.d_year = 2001 AND d1.d_date_sk = ss_sold_date_sk AND i_item_sk = ss_item_sk AND s_store_sk = ss_store_sk AND s_state IN ('TN', 'SD', 'AL', 'SC', 'OH', 'LA', 'MO', 'GA')
GROUP BY ROLLUP(i_category, i_class)
ORDER BY lochierarchy DESC, CASE WHEN lochierarchy = 0 THEN i_category END, rank_within_parent LIMIT 100;
