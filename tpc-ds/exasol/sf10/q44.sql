-- Q44: Store Sales Rank
SELECT asceding.rnk, i1.i_product_name best_performing, i2.i_product_name worst_performing
FROM (
  SELECT item_sk, RANK() OVER (ORDER BY rank_col ASC) rnk
  FROM (SELECT ss_item_sk item_sk, AVG(ss_net_profit) rank_col FROM TPCDS_10GB.STORE_SALES ss1 WHERE ss_store_sk = 4 GROUP BY ss_item_sk HAVING AVG(ss_net_profit) > 0.9 * (SELECT AVG(ss_net_profit) rank_col FROM TPCDS_10GB.STORE_SALES WHERE ss_store_sk = 4 AND ss_addr_sk IS NULL GROUP BY ss_store_sk)) V1
) asceding,
(SELECT item_sk, RANK() OVER (ORDER BY rank_col DESC) rnk
  FROM (SELECT ss_item_sk item_sk, AVG(ss_net_profit) rank_col FROM TPCDS_10GB.STORE_SALES ss1 WHERE ss_store_sk = 4 GROUP BY ss_item_sk HAVING AVG(ss_net_profit) > 0.9 * (SELECT AVG(ss_net_profit) rank_col FROM TPCDS_10GB.STORE_SALES WHERE ss_store_sk = 4 AND ss_addr_sk IS NULL GROUP BY ss_store_sk)) V2
) desceding,
TPCDS_10GB.ITEM i1, TPCDS_10GB.ITEM i2
WHERE asceding.rnk = desceding.rnk AND i1.i_item_sk = asceding.item_sk AND i2.i_item_sk = desceding.item_sk
ORDER BY asceding.rnk LIMIT 10;
