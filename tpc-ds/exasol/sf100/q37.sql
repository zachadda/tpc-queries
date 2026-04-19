-- Q37: Catalog Item Inventory
SELECT i_item_id, i_item_desc, i_current_price
FROM TPCDS_100GB.ITEM, TPCDS_100GB.INVENTORY, TPCDS_100GB.DATE_DIM, TPCDS_100GB.CATALOG_SALES
WHERE i_current_price BETWEEN 68 AND 68+30 AND inv_item_sk = i_item_sk AND d_date_sk = inv_date_sk
AND d_date BETWEEN DATE '2000-02-01' AND DATE '2000-02-01' + INTERVAL '60' DAY AND i_manufact_id IN (677, 940, 694, 808)
AND inv_quantity_on_hand BETWEEN 100 AND 500 AND cs_item_sk = i_item_sk
GROUP BY i_item_id, i_item_desc, i_current_price
ORDER BY i_item_id LIMIT 100;
