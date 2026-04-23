#!/bin/bash
# 每日備份 Neon DB → JSON 快照存到 teaking-images/backups/
# 設定 cron: 0 3 * * * /Users/user/Downloads/teaking-images/backups/backup_neon.sh

NEON_DSN="postgresql://neondb_owner:npg_k80oArlncEZp@ep-purple-dream-a1vynrek.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
BACKUP_DIR="/Users/user/Downloads/teaking-images/backups"
DATE=$(date +%Y%m%d_%H%M%S)
OUTFILE="$BACKUP_DIR/profiles_snapshot_$DATE.json"

# 用 python3 從 Neon 匯出 JSON
python3 - <<EOF
import psycopg2, json
from datetime import datetime

conn = psycopg2.connect("$NEON_DSN")
cur = conn.cursor()
cur.execute("""
    SELECT id, name, age, height, weight, cup, nationality,
           location, district, type, "imageUrl", gallery, price,
           "basicServices", "addonServices", "isNew", "isAvailable",
           tags, remarks, "createdAt", "updatedAt"
    FROM profiles ORDER BY id
""")
cols = [d[0] for d in cur.description]
rows = []
for row in cur.fetchall():
    r = {}
    for k, v in zip(cols, row):
        if hasattr(v, 'isoformat'):
            r[k] = v.isoformat()
        else:
            r[k] = v
    rows.append(r)
conn.close()

with open("$OUTFILE", "w", encoding="utf-8") as f:
    json.dump(rows, f, ensure_ascii=False, indent=2)

print(f"✅ 備份完成：{len(rows)} 位 → $OUTFILE")
EOF

# 只保留最近 30 個備份
ls -t "$BACKUP_DIR"/profiles_snapshot_*.json 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null
echo "🗂 備份目錄現有 $(ls $BACKUP_DIR/profiles_snapshot_*.json 2>/dev/null | wc -l) 個快照"
