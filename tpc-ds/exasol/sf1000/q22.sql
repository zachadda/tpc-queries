-- Q22: Inventory Quantity Bands
SELECT i_product_name, i_brand, i_class, i_category,
  AVG(inv_quantity_on_hand) qoh
FROM TPCDS_1000GB.INVENTORY, TPCDS_1000GB.DATE_DIM, TPCDS_1000GB.ITEM, TPCDS_1000GB.WAREHOUSE
WHERE inv_date_sk = d_date_sk AND inv_item_sk = i_item_sk AND inv_warehouse_sk = w_warehouse_sk AND d_month_seq BETWEEN 1200 AND 1200+11
GROUP BY ROLLUP(i_product_name, i_brand, i_class, i_category)
ORDER BY qoh, i_product_name, i_brand, i_class, i_category LIMIT 100;
