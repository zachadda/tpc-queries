# TPC Benchmark Queries

Standard TPC-H and TPC-DS benchmark queries adapted for Exasol, Snowflake, Databricks, and BigQuery.

## Structure

```
tpc-h/
  {database}/
    all_queries.sql          # All 22 queries in one file
    sf1/                     # Individual queries for Scale Factor 1 (1 GB)
      q01.sql ... q22.sql
      all_queries.sql        # All queries with OPEN SCHEMA for this SF
    sf10/                    # Scale Factor 10 (10 GB)
    sf100/                   # Scale Factor 100 (100 GB)
    sf1000/                  # Scale Factor 1000 (1 TB)
    ddl/                     # DDL scripts (coming soon)

tpc-ds/
  {database}/
    sf1/                     # Individual queries for Scale Factor 1
      q01.sql ... q99.sql
      all_queries.sql
    sf10/                    # Scale Factor 10
    sf100/                   # Scale Factor 100
    sf1000/                  # Scale Factor 1000
    ddl/                     # DDL scripts (coming soon)

scripts/                     # Data import scripts (coming soon)
```

## Databases

| Database | TPC-H | TPC-DS | Notes |
|----------|-------|--------|-------|
| **Exasol** | 22 queries, 4 SFs | 99 queries, 4 SFs | SF-specific SQL for 11 TPC-DS queries |
| **Snowflake** | 22 queries | Coming soon | Standard SQL dialect |
| **Databricks** | 22 queries | Coming soon | Spark SQL dialect |
| **BigQuery** | 22 queries | Coming soon | Standard SQL with BigQuery extensions |

## TPC-H (22 Queries)

The [TPC-H](http://www.tpc.org/tpch/) benchmark models a decision support workload with 22 queries covering:
- Pricing, shipping, and order analysis
- Supplier and customer segmentation
- Revenue and profit reporting

Queries are identical across all scale factors. SQL syntax is adapted per database dialect.

### Query Adaptations

All 22 TPC-H queries produce results identical to the official TPC-H specification. Four queries use modern SQL patterns instead of the original spec syntax:

| Query | Official Spec | This Repo | Why |
|-------|--------------|-----------|-----|
| **Q13** | Subquery in FROM | CTE (`WITH`) | Readability — semantically identical |
| **Q15** | CREATE VIEW / DROP VIEW | CTE (`WITH`) | Industry standard — every vendor does this |
| **Q17** | Correlated subquery | Window function (`AVG() OVER PARTITION BY`) | Avoids redundant table scans — same result |
| **Q20** | Nested correlated subqueries | Pre-filtered JOINs with CTEs | Avoids redundant table scans — same result |

All queries return bit-identical results to the TPC-H specification.

### Scale Factors

| SF | Data Size | Schema (Exasol) |
|----|-----------|-----------------|
| 1 | ~1 GB | TPCH_1GB |
| 10 | ~10 GB | TPCH_10GB |
| 100 | ~100 GB | TPCH_100GB |
| 1000 | ~1 TB | TPCH_1000GB |

## TPC-DS (99 Queries)

The [TPC-DS](http://www.tpc.org/tpcds/) benchmark models a more complex decision support workload with 99 queries spanning:
- Store sales, catalog sales, web sales
- Inventory, promotions, returns
- Customer demographics and segmentation

**Important:** 11 TPC-DS queries have scale-factor-specific SQL (different filter values, and in some cases different query structures). Always use the correct SF directory.

### Queries that vary by Scale Factor

| Query | What varies |
|-------|------------|
| Q14 | SF1/SF100: ROLLUP aggregation. SF10/SF1000: year-over-year comparison (different structure) |
| Q16 | County filter values |
| Q23 | Query structure (column selection, grouping) |
| Q24 | Color filter value |
| Q27 | State filter values |
| Q30 | State filter values |
| Q34 | County filter values |
| Q36 | State filter values |
| Q39 | Variance threshold |
| Q46 | City filter values (same for SF10/100/1000, different for SF1) |
| Q73 | County filter values |

### Scale Factors

| SF | Data Size | Schema (Exasol) |
|----|-----------|-----------------|
| 1 | ~1 GB | TPCDS_1GB |
| 10 | ~10 GB | TPCDS_10GB |
| 100 | ~100 GB | TPCDS_100GB |
| 1000 | ~1 TB | TPCDS_1000GB |

## Usage

### Exasol

```sql
-- Run all TPC-H queries at SF100
OPEN SCHEMA TPCH_100GB;
-- Then execute queries from tpc-h/exasol/sf100/

-- Run individual TPC-DS query at SF1000
OPEN SCHEMA TPCDS_1000GB;
-- Execute from tpc-ds/exasol/sf1000/q01.sql
```

### Snowflake

```sql
USE SCHEMA TPCH_SF100;
-- Execute from tpc-h/snowflake/sf100/
```

## Data Loading

Data loading and DDL scripts are coming soon in the `ddl/` and `scripts/` directories.

For Exasol, you can use the [Exasol Public Demo System](https://www.exasol.com/cloud-testing/) which has TPC-H and TPC-DS data pre-loaded at all scale factors.

## Contributing

PRs welcome for:
- TPC-DS queries adapted for Snowflake, Databricks, BigQuery
- DDL scripts for table creation
- Data import/generation scripts
- Query optimizations per platform

## License

The TPC-H and TPC-DS benchmark specifications are owned by the [Transaction Processing Performance Council (TPC)](http://www.tpc.org/). These SQL adaptations are provided for benchmarking and educational purposes.
