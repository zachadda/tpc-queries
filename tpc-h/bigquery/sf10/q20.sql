-- Q20 Potential Part Promotion
WITH canada_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_address
    FROM supplier s
    JOIN nation n ON n.n_nationkey = s.s_nationkey
    WHERE n.n_name = 'CANADA'
),
forest_parts AS (
    SELECT p_partkey FROM part WHERE p_name LIKE 'forest%'
),
li_canada_forest_1994 AS (
    SELECT li.l_partkey, li.l_suppkey, SUM(li.l_quantity) AS qty_sum
    FROM lineitem li
    JOIN canada_suppliers s ON s.s_suppkey = li.l_suppkey
    JOIN forest_parts fp ON fp.p_partkey = li.l_partkey
    WHERE li.l_shipdate >= DATE '1994-01-01'
        AND li.l_shipdate < DATE '1995-01-01'
    GROUP BY li.l_partkey, li.l_suppkey
)
SELECT s.s_name, s.s_address
FROM canada_suppliers s
WHERE EXISTS (
    SELECT 1
    FROM partsupp ps
    JOIN forest_parts fp ON fp.p_partkey = ps.ps_partkey
    JOIN li_canada_forest_1994 li
        ON li.l_partkey = ps.ps_partkey AND li.l_suppkey = ps.ps_suppkey
    WHERE ps.ps_suppkey = s.s_suppkey
        AND ps.ps_availqty > 0.5 * li.qty_sum
)
ORDER BY s.s_name;
