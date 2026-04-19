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
