select
        l_returnflag,
        l_linestatus,
        sum(l_quantity) as sum_qty,
        sum(l_extendedprice) as sum_base_price,
        sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
        sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
        avg(l_quantity) as avg_qty,
        avg(l_extendedprice) as avg_price,
        avg(l_discount) as avg_disc,
        count(*) as count_order
from
        lineitem
where
        --l_shipdate <= date '1998-12-01' - interval '90' day (3) --fails
        --l_shipdate <= DATE '1998-12-01' - INTERVAL 90 DAYS --works
        --l_shipdate <= date_sub(DATE '1998-12-01', 90) --works
        l_shipdate <= DATEADD(day, -116, '1998-12-01') --works
group by
        l_returnflag,
        l_linestatus
order by
        l_returnflag,
        l_linestatus;
select
        s_acctbal,
        s_name,
        n_name,
        p_partkey,
        p_mfgr,
        s_address,
        s_phone,
        s_comment
from
        part,
        supplier,
        partsupp,
        nation,
        region
where
        p_partkey = ps_partkey
        and s_suppkey = ps_suppkey
        and p_size = 15
        and p_type like '%BRASS'
        and s_nationkey = n_nationkey
        and n_regionkey = r_regionkey
        and r_name = 'EUROPE'
        and ps_supplycost = (
                select
                        min(ps_supplycost)
                from
                        partsupp,
                        supplier,
                        nation,
                        region
                where
                        p_partkey = ps_partkey
                        and s_suppkey = ps_suppkey
                        and s_nationkey = n_nationkey
                        and n_regionkey = r_regionkey
                        and r_name = 'EUROPE'
        )
order by
        s_acctbal desc,
        n_name,
        s_name,
        p_partkey
LIMIT 100
;
SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue, o_orderdate, o_shippriority FROM customer, orders, lineitem WHERE c_mktsegment = 'BUILDING' AND c_custkey = o_custkey AND l_orderkey = o_orderkey AND o_orderdate < DATE '1995-03-15' AND l_shipdate > DATE '1995-03-15' GROUP BY l_orderkey, o_orderdate, o_shippriority ORDER BY revenue DESC, o_orderdate LIMIT 10;
SELECT o_orderpriority, COUNT(*) AS order_count FROM orders WHERE o_orderdate >= DATE '1993-07-01' AND o_orderdate < DATE '1993-07-01' + interval '3' MONTH AND EXISTS ( SELECT * FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate ) GROUP BY o_orderpriority ORDER BY o_orderpriority;
SELECT n_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue FROM customer, orders, lineitem, supplier, nation, region WHERE c_custkey = o_custkey AND l_orderkey = o_orderkey AND l_suppkey = s_suppkey AND c_nationkey = s_nationkey AND s_nationkey = n_nationkey AND n_regionkey = r_regionkey AND r_name = 'ASIA' AND o_orderdate >= DATE '1994-01-01' AND o_orderdate < DATE '1994-01-01' + interval '1' YEAR GROUP BY n_name ORDER BY revenue DESC;
SELECT SUM(l_extendedprice * l_discount) AS revenue FROM lineitem WHERE l_shipdate >= DATE '1994-01-01' AND l_shipdate < DATE '1994-01-01' + interval '1' YEAR AND l_discount BETWEEN .06 - 0.01 AND .06 + 0.01 AND l_quantity < 24;
SELECT supp_nation, cust_nation, l_year, SUM(volume) AS revenue FROM ( SELECT n1.n_name AS supp_nation, n2.n_name AS cust_nation, extract(YEAR FROM l_shipdate) AS l_year, l_extendedprice * (1 - l_discount) AS volume FROM supplier, lineitem, orders, customer, nation n1, nation n2 WHERE s_suppkey = l_suppkey AND o_orderkey = l_orderkey AND c_custkey = o_custkey AND s_nationkey = n1.n_nationkey AND c_nationkey = n2.n_nationkey AND ( ( n1.n_name = 'FRANCE' AND n2.n_name = 'GERMANY') OR ( n1.n_name = 'GERMANY' AND n2.n_name = 'FRANCE') ) AND l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31' ) AS shipping GROUP BY supp_nation, cust_nation, l_year ORDER BY supp_nation, cust_nation, l_year;
SELECT o_year, SUM( CASE WHEN nation = 'BRAZIL' THEN volume ELSE 0 END) / SUM(volume) AS mkt_share FROM ( SELECT extract(YEAR FROM o_orderdate) AS o_year, l_extendedprice * (1 - l_discount) AS volume, n2.n_name AS nation FROM part, supplier, lineitem, orders, customer, nation n1, nation n2, region WHERE p_partkey = l_partkey AND s_suppkey = l_suppkey AND l_orderkey = o_orderkey AND o_custkey = c_custkey AND c_nationkey = n1.n_nationkey AND n1.n_regionkey = r_regionkey AND r_name = 'AMERICA' AND s_nationkey = n2.n_nationkey AND o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31' AND p_type = 'ECONOMY ANODIZED STEEL' ) AS all_nations GROUP BY o_year ORDER BY o_year;
SELECT nation, o_year, SUM(amount) AS sum_profit FROM ( SELECT n_name AS nation, extract(YEAR FROM o_orderdate) AS o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity AS amount FROM part, supplier, lineitem, partsupp, orders, nation WHERE s_suppkey = l_suppkey AND ps_suppkey = l_suppkey AND ps_partkey = l_partkey AND p_partkey = l_partkey AND o_orderkey = l_orderkey AND s_nationkey = n_nationkey AND p_name LIKE '%green%' ) AS profit GROUP BY nation, o_year ORDER BY nation, o_year DESC;
SELECT c_custkey, c_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue, c_acctbal, n_name, c_address, c_phone, c_comment FROM customer, orders, lineitem, nation WHERE c_custkey = o_custkey AND l_orderkey = o_orderkey AND o_orderdate >= DATE '1993-10-01' AND o_orderdate < DATE '1993-10-01' + interval '3' MONTH AND l_returnflag = 'R' AND c_nationkey = n_nationkey GROUP BY c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment ORDER BY revenue DESC LIMIT 20;
SELECT ps_partkey, SUM(ps_supplycost * ps_availqty) AS VALUE FROM partsupp, supplier, nation WHERE ps_suppkey = s_suppkey AND s_nationkey = n_nationkey AND n_name = 'GERMANY' GROUP BY ps_partkey HAVING SUM(ps_supplycost * ps_availqty) > ( SELECT SUM(ps_supplycost * ps_availqty) * 0.0000001000 FROM partsupp, supplier, nation WHERE ps_suppkey = s_suppkey AND s_nationkey = n_nationkey AND n_name = 'GERMANY' ) ORDER BY "VALUE" DESC;
SELECT l_shipmode, SUM( CASE WHEN o_orderpriority = '1-URGENT' OR o_orderpriority = '2-HIGH' THEN 1 ELSE 0 END) AS high_line_count, SUM( CASE WHEN o_orderpriority <> '1-URGENT' AND o_orderpriority <> '2-HIGH' THEN 1 ELSE 0 END) AS low_line_count FROM orders, lineitem WHERE o_orderkey = l_orderkey AND l_shipmode IN ('MAIL', 'SHIP') AND l_commitdate < l_receiptdate AND l_shipdate < l_commitdate AND l_receiptdate >= DATE '1994-01-01' AND l_receiptdate < DATE '1994-01-01' + interval '1' YEAR GROUP BY l_shipmode ORDER BY l_shipmode;
WITH orders_filtered AS ( SELECT o_custkey, COUNT(*) AS cnt FROM orders WHERE o_comment NOT LIKE '%special%requests%' GROUP BY o_custkey ), per_customer AS ( SELECT c.c_custkey, COALESCE(o.cnt, 0) AS c_count FROM customer c LEFT JOIN orders_filtered o ON c.c_custkey = o.o_custkey ) SELECT c_count, COUNT(*) AS custdist FROM per_customer GROUP BY c_count ORDER BY custdist DESC, c_count DESC;
SELECT 100.00 * SUM( CASE WHEN p_type LIKE 'PROMO%' THEN l_extendedprice * (1 - l_discount) ELSE 0 END) / SUM(l_extendedprice * (1 - l_discount)) AS promo_revenue FROM lineitem, part WHERE l_partkey = p_partkey AND l_shipdate >= DATE '1995-09-01' AND l_shipdate < DATE '1995-09-01' + interval '1' MONTH;
WITH revenue0 ( supplier_no, total_revenue ) AS ( SELECT l_suppkey, SUM(l_extendedprice * (1 - l_discount)) FROM lineitem WHERE l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1996-01-01' + interval '3' MONTH GROUP BY l_suppkey ) SELECT s_suppkey, s_name, s_address, s_phone, total_revenue FROM supplier, revenue0 WHERE s_suppkey = supplier_no AND total_revenue = ( SELECT MAX(total_revenue) FROM revenue0 ) ORDER BY s_suppkey;
SELECT p_brand, p_type, p_size, COUNT(DISTINCT ps_suppkey) AS supplier_cnt FROM partsupp, part WHERE p_partkey = ps_partkey AND p_brand <> 'Brand#45' AND p_type NOT LIKE 'MEDIUM POLISHED%' AND p_size IN (49, 14, 23, 45, 19, 3, 36, 9) AND ps_suppkey NOT IN ( SELECT s_suppkey FROM supplier WHERE s_comment LIKE '%Customer%Complaints%' ) GROUP BY p_brand, p_type, p_size ORDER BY supplier_cnt DESC, p_brand, p_type, p_size;
WITH parts AS ( SELECT p_partkey FROM part WHERE p_brand = 'Brand#23' AND p_container = 'MED BOX' ), li AS ( SELECT li.l_extendedprice, li.l_quantity, 0.2 * AVG(li.l_quantity) OVER (PARTITION BY li.l_partkey) AS qty_thresh FROM lineitem li JOIN parts p ON p.p_partkey = li.l_partkey ) SELECT SUM(l_extendedprice) / 7.0 AS avg_yearly FROM li WHERE l_quantity < qty_thresh;
SELECT c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, SUM(l_quantity) FROM customer, orders, lineitem WHERE o_orderkey IN ( SELECT l_orderkey FROM lineitem GROUP BY l_orderkey HAVING SUM(l_quantity) > 300 ) AND c_custkey = o_custkey AND o_orderkey = l_orderkey GROUP BY c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice ORDER BY o_totalprice DESC, o_orderdate LIMIT 100;
SELECT SUM(l_extendedprice* (1 - l_discount)) AS revenue FROM lineitem, part WHERE ( p_partkey = l_partkey AND p_brand = 'Brand#12' AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') AND l_quantity >= 1 AND l_quantity <= 1 + 10 AND p_size BETWEEN 1 AND 5 AND l_shipmode IN ('AIR', 'AIR REG') AND l_shipinstruct = 'DELIVER IN PERSON' ) OR ( p_partkey = l_partkey AND p_brand = 'Brand#23' AND p_container IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') AND l_quantity >= 10 AND l_quantity <= 10 + 10 AND p_size BETWEEN 1 AND 10 AND l_shipmode IN ('AIR', 'AIR REG') AND l_shipinstruct = 'DELIVER IN PERSON' ) OR ( p_partkey = l_partkey AND p_brand = 'Brand#34' AND p_container IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') AND l_quantity >= 20 AND l_quantity <= 20 + 10 AND p_size BETWEEN 1 AND 15 AND l_shipmode IN ('AIR', 'AIR REG') AND l_shipinstruct = 'DELIVER IN PERSON' );
WITH canada_suppliers AS ( SELECT s.s_suppkey, s.s_name, s.s_address FROM supplier s JOIN nation n ON n.n_nationkey = s.s_nationkey WHERE n.n_name = 'CANADA' ), forest_parts AS ( SELECT p_partkey FROM part WHERE p_name LIKE 'forest%' ), li_canada_forest_1994 AS ( /*-- Aggregate only the relevant slice of lineitem*/ SELECT li.l_partkey, li.l_suppkey, SUM(li.l_quantity) AS qty_sum FROM lineitem li JOIN canada_suppliers s ON s.s_suppkey = li.l_suppkey JOIN forest_parts fp ON fp.p_partkey = li.l_partkey WHERE li.l_shipdate >= DATE '1994-01-01' AND li.l_shipdate < DATE '1995-01-01' GROUP BY li.l_partkey, li.l_suppkey ) SELECT s.s_name, s.s_address FROM canada_suppliers s WHERE EXISTS ( SELECT 1 FROM partsupp ps JOIN forest_parts fp ON fp.p_partkey = ps.ps_partkey JOIN li_canada_forest_1994 li /*-- INNER JOIN: require matching lineitems*/ ON li.l_partkey = ps.ps_partkey AND li.l_suppkey = ps.ps_suppkey WHERE ps.ps_suppkey = s.s_suppkey AND ps.ps_availqty > 0.5 * li.qty_sum ) ORDER BY s.s_name;
SELECT s_name, COUNT(*) AS numwait FROM supplier, lineitem l1, orders, nation WHERE s_suppkey = l1.l_suppkey AND o_orderkey = l1.l_orderkey AND o_orderstatus = 'F' AND l1.l_receiptdate > l1.l_commitdate AND EXISTS ( SELECT * FROM lineitem l2 WHERE l2.l_orderkey = l1.l_orderkey AND l2.l_suppkey <> l1.l_suppkey ) AND NOT EXISTS ( SELECT * FROM lineitem l3 WHERE l3.l_orderkey = l1.l_orderkey AND l3.l_suppkey <> l1.l_suppkey AND l3.l_receiptdate > l3.l_commitdate ) AND s_nationkey = n_nationkey AND n_name = 'SAUDI ARABIA' GROUP BY s_name ORDER BY numwait DESC, s_name LIMIT 100;
SELECT cntrycode, COUNT(*) AS numcust, SUM(c_acctbal) AS totacctbal FROM ( SELECT substring(c_phone FROM 1 FOR 2) AS cntrycode, c_acctbal FROM customer WHERE substring(c_phone FROM 1 FOR 2) IN ('13', '31', '23', '29', '30', '18', '17') AND c_acctbal > ( SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal > 0.00 AND substring(c_phone FROM 1 FOR 2) IN ('13', '31', '23', '29', '30', '18', '17') ) AND NOT EXISTS ( SELECT * FROM orders WHERE o_custkey = c_custkey ) ) AS custsale GROUP BY cntrycode ORDER BY cntrycode;
