-- ۱) یک کوئری روی Distributed: کل داده‌ها
SELECT count() AS total FROM lab.events_dist;

-- ۲) پخش داده بین شاردها (هر شارد از یک رپلیکا خوانده می‌شود)
SELECT _shard_num AS shard, count() AS rows, uniq(user_id) AS users
FROM lab.events_dist GROUP BY shard ORDER BY shard;

-- ۳) تعداد ردیف روی هر ۶ نود: رپلیکاهای هر شارد باید دقیقاً برابر باشند
SELECT hostName() AS node, count() AS rows
FROM clusterAllReplicas('lab_cluster', lab.events_local)
GROUP BY node ORDER BY node;

-- ۴) هر user_id فقط باید روی یک شارد باشد (باید 0 برگرداند)
SELECT count() AS users_on_both_shards FROM (
  SELECT user_id FROM lab.events_dist GROUP BY user_id HAVING uniqExact(_shard_num) > 1);

-- ۵) وضعیت رپلیکیشن
SELECT hostName() AS node, table, is_leader, total_replicas, active_replicas, absolute_delay
FROM clusterAllReplicas('lab_cluster', system.replicas) WHERE database='lab' ORDER BY node;
