CREATE DATABASE IF NOT EXISTS lab ON CLUSTER lab_cluster;

-- جدول محلی: روی هر ۶ نود ساخته می‌شود؛ رپلیکاهای یک شارد مسیر Keeper یکسان دارند
CREATE TABLE IF NOT EXISTS lab.events_local ON CLUSTER lab_cluster
(
    event_id   UInt64,
    user_id    UInt32,
    event_type LowCardinality(String),
    amount     Float32,
    event_time DateTime
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/lab/events_local', '{replica}')
PARTITION BY toYYYYMM(event_time)
ORDER BY (user_id, event_time);

-- جدول توزیع‌شده: کلید شاردینگ = cityHash64(user_id)
CREATE TABLE IF NOT EXISTS lab.events_dist ON CLUSTER lab_cluster
AS lab.events_local
ENGINE = Distributed(lab_cluster, lab, events_local, cityHash64(user_id));
