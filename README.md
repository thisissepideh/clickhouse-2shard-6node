# کلاستر ClickHouse: ۲ شارد × ۳ رپلیکا (Docker Compose)

## معماری
- ۶ نود ClickHouse: `ch-s{1,2}-r{1,2,3}` (شارد ۱ و ۲، هر کدام ۳ رپلیکا)
- ۳ نود ClickHouse Keeper (`keeper1..3`) برای هماهنگی رپلیکیشن (کورام ۳تایی؛ با از دست رفتن ۱ نود همچنان کار می‌کند)
- `internal_replication=true`: Distributed فقط به یک رپلیکای هر شارد می‌نویسد و کپی‌کردن به عهدهٔ ReplicatedMergeTree است (جلوگیری از نوشتن دوباره)
- ارتباط بین نودها با کاربر اختصاصی `ch_cluster` (فایل `config/users.xml`) انجام می‌شود، چون کاربر `default` در ایمیج Docker فقط از localhost مجاز است
- ماکروها (`{shard}`, `{replica}`) در `config/macros-*.xml` برای هر نود جدا تعریف شده‌اند

## اجرا
```bash
./run.sh
```
یا مرحله‌به‌مرحله: `docker compose up -d` سپس اجرای `sql/01_create.sql` ، `02_insert.sql` ، `03_verify.sql` با `docker exec -i ch-s1-r1 clickhouse-client --multiquery < فایل`

## دیتاست
جدول رویدادهای کاربران (`events`): `event_id, user_id, event_type, amount, event_time` — ۱۰۰٬۰۰۰ ردیف ساختگی، حدود ۱۰٬۰۰۰ کاربر.

## کلید شاردینگ: `cityHash64(user_id)`
- **توزیع یکنواخت**: هش، شناسه‌ها را تقریباً برابر پخش می‌کند (نه لزوماً دقیقاً ۵۰/۵۰).
- **هم‌مکانی (locality)**: همهٔ رویدادهای یک کاربر روی یک شارد می‌مانند؛ پس GROUP BY / JOIN روی `user_id` بدون جابه‌جایی داده بین شاردها انجام می‌شود (کوئری ۴ این را اثبات می‌کند).
- **چرا نه `event_time` یا `event_type`؟** event_type فقط ۴ مقدار دارد (توزیع نامتعادل)، و زمان باعث می‌شود همهٔ نوشتن‌های جدید به یک شارد بروند (hot shard).

## تست تحمل خطا
```bash
docker stop ch-s1-r1
docker exec -i ch-s1-r2 clickhouse-client -q "SELECT count() FROM lab.events_dist"   # همان عدد قبلی
docker start ch-s1-r1   # بعد از چند ثانیه همگام می‌شود؛ 03_verify.sql را دوباره بزنید
```
اگر استاد تعداد نود دیگری خواست: فقط بلوک‌های `<shard>/<replica>` در `config/cluster.xml`، سرویس‌های compose و ماکروها را کم/زیاد کنید.
