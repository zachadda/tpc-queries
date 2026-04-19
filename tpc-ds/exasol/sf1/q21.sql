-- Q21: Inventory Analysis
SELECT * FROM (
  SELECT w_warehouse_name, i_item_id,
    SUM(CASE WHEN d_date < DATE '2000-03-11' THEN inv_quantity_on_hand ELSE 0 END) AS inv_before,
    SUM(CASE WHEN d_date >= DATE '2000-03-11' THEN inv_quantity_on_hand ELSE 0 END) AS inv_after
  FROM TPCDS_1GB.INVENTORY, TPCDS_1GB.WAREHOUSE, TPCDS_1GB.ITEM, TPCDS_1GB.DATE_DIM
  WHERE i_current_price BETWEEN 0.99 AND 1.49 AND i_item_sk = inv_item_sk AND inv_warehouse_sk = w_warehouse_sk AND inv_date_sk = d_date_sk
  AND d_date BETWEEN DATE '2000-03-11' - INTERVAL '30' DAY AND DATE '2000-03-11' + INTERVAL '30' DAY
  GROUP BY w_warehouse_name, i_item_id
) x
WHERE (CASE WHEN inv_before > 0 THEN inv_after / inv_before ELSE NULL END) BETWEEN 2.0/3.0 AND 3.0/2.0
ORDER BY w_warehouse_name, i_item_id LIMIT 100;
