-- Q83: Returns by Item Date
WITH sr_items AS (
  SELECT i_item_id item_id, SUM(sr_return_quantity) sr_item_qty
  FROM TPCDS_1GB.STORE_RETURNS, TPCDS_1GB.ITEM, TPCDS_1GB.DATE_DIM
  WHERE sr_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1GB.DATE_DIM WHERE d_week_seq IN (SELECT d_week_seq FROM TPCDS_1GB.DATE_DIM WHERE d_date IN (DATE '2000-06-30', DATE '2000-09-27', DATE '2000-11-17')))
  AND sr_returned_date_sk = d_date_sk
  GROUP BY i_item_id
),
cr_items AS (
  SELECT i_item_id item_id, SUM(cr_return_quantity) cr_item_qty
  FROM TPCDS_1GB.CATALOG_RETURNS, TPCDS_1GB.ITEM, TPCDS_1GB.DATE_DIM
  WHERE cr_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1GB.DATE_DIM WHERE d_week_seq IN (SELECT d_week_seq FROM TPCDS_1GB.DATE_DIM WHERE d_date IN (DATE '2000-06-30', DATE '2000-09-27', DATE '2000-11-17')))
  AND cr_returned_date_sk = d_date_sk
  GROUP BY i_item_id
),
wr_items AS (
  SELECT i_item_id item_id, SUM(wr_return_quantity) wr_item_qty
  FROM TPCDS_1GB.WEB_RETURNS, TPCDS_1GB.ITEM, TPCDS_1GB.DATE_DIM
  WHERE wr_item_sk = i_item_sk AND d_date IN (SELECT d_date FROM TPCDS_1GB.DATE_DIM WHERE d_week_seq IN (SELECT d_week_seq FROM TPCDS_1GB.DATE_DIM WHERE d_date IN (DATE '2000-06-30', DATE '2000-09-27', DATE '2000-11-17')))
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
