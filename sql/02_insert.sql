SET insert_distributed_sync = 1;

INSERT INTO lab.events_dist
SELECT
    number                                                    AS event_id,
    toUInt32(rand() % 10000)                                  AS user_id,
    arrayElement(['view','click','cart','purchase'], 1 + rand() % 4) AS event_type,
    round(rand() % 50000 / 100, 2)                            AS amount,
    toDateTime('2026-01-01 00:00:00') + (rand() % (86400 * 300)) AS event_time
FROM numbers(100000);
