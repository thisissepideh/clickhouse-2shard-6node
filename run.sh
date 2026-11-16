#!/usr/bin/env bash
set -e
docker compose up -d
echo "منتظر آماده‌شدن نودها..."; sleep 25
C() { docker exec -i ch-s1-r1 clickhouse-client --multiquery "$@"; }
C < sql/01_create.sql
C -q "TRUNCATE TABLE lab.events_local ON CLUSTER lab_cluster"
C < sql/02_insert.sql
C --format PrettyCompact < sql/03_verify.sql
