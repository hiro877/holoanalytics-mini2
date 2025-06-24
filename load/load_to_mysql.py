import os
import tempfile
import boto3
import pandas as pd
import mysql.connector
from dotenv import load_dotenv

load_dotenv()

# ---- 1. env ----
BUCKET      = os.environ["S3_BUCKET"]           # holoanalytics-raw
S3_KEY      = f"youtube/{os.environ['LOAD_DATE']}.csv"  # 例: 2025-06-23.csv
AWS_REGION  = os.getenv("AWS_REGION", "ap-northeast-1")

DB_HOST     = os.environ["RDS_HOST"]            # holoanalytics-dev.cxxxx.rds.amazonaws.com
DB_USER     = os.environ["RDS_USER"]            # tatto
DB_PASS     = os.environ["RDS_PASS"]
DB_NAME     = "raw"

# ---- 2. S3 から一時ファイルにDL ----
with tempfile.NamedTemporaryFile(delete=False, suffix=".csv") as tmp:
    tmp_path = tmp.name  # パスを保存して、閉じる（Windows対策）

s3 = boto3.client("s3", region_name=AWS_REGION)
s3.download_file(BUCKET, S3_KEY, tmp_path)
print(f"[✓] downloaded {S3_KEY} to {tmp_path}")

# ---- 3. CSV → pandas DataFrame ----
df = pd.read_csv(tmp_path)
print(f"[✓] read {len(df)} rows")
print("[✓] DataFrame columns:", df.columns.tolist())

# ---- 4. MySQL へ接続 ----
cnx = mysql.connector.connect(
    host=DB_HOST, user=DB_USER, password=DB_PASS, database=DB_NAME, autocommit=False
)
cur = cnx.cursor()

# ---- Debug ----
cur = cnx.cursor()
cur.execute("SELECT DATABASE()")
print("[DEBUG] current DB =", cur.fetchone()[0])   # ここで raw と出るか？
cur.execute("SHOW CREATE TABLE youtube_stats")
print("[DEBUG] table DDL:\n", cur.fetchone()[1])

# ---- 5. INSERT (bulk) ----
sql = """
INSERT INTO raw.youtube_stats   -- ★ raw. を付けた
(date, channel_id, title, viewCount, subscriberCount, videoCount)
VALUES (%s,%s,%s,%s,%s,%s)
ON DUPLICATE KEY UPDATE
  viewCount        = VALUES(viewCount),
  subscriberCount  = VALUES(subscriberCount),
  videoCount       = VALUES(videoCount)
"""
cur.executemany(sql, df.to_records(index=False).tolist())
cnx.commit()
print(f"[✓] inserted/updated {cur.rowcount} rows")

# ---- 6. 行数検証 ----
cur.execute("SELECT COUNT(*) FROM youtube_stats")
print("[✓] table rowcount =", cur.fetchone()[0])

cur.close()
cnx.close()

# ---- 7. 一時ファイル削除（任意） ----
try:
    os.remove(tmp_path)
    print(f"[✓] temp file {tmp_path} deleted")
except Exception as e:
    print(f"[!] failed to delete temp file: {e}")
