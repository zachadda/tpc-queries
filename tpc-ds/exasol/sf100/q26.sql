-- Q26: Catalog Sales Promo Analysis
SELECT i_item_id, AVG(cs_quantity) agg1, AVG(cs_list_price) agg2, AVG(cs_coupon_amt) agg3, AVG(cs_sales_price) agg4
FROM TPCDS_100GB.CATALOG_SALES, TPCDS_100GB.CUSTOMER_DEMOGRAPHICS, TPCDS_100GB.DATE_DIM, TPCDS_100GB.ITEM, TPCDS_100GB.PROMOTION
WHERE cs_sold_date_sk = d_date_sk AND cs_item_sk = i_item_sk AND cs_bill_cdemo_sk = cd_demo_sk AND cs_promo_sk = p_promo_sk
AND cd_gender = 'M' AND cd_marital_status = 'S' AND cd_education_status = 'College'
AND d_year = 2000 AND (p_channel_email = 'N' OR p_channel_event = 'N')
GROUP BY i_item_id
ORDER BY i_item_id LIMIT 100;
