# extract/youtube_fetch.py
import os, datetime, csv, pathlib, boto3
from dotenv import load_dotenv
from googleapiclient.discovery import build

# ------------------------------------------------------------------ #
# 1. 環境変数ロード
# ------------------------------------------------------------------ #
load_dotenv()
API_KEY    = os.environ["YT_API_KEY"]
CHANNEL_ID = os.environ["CHANNEL_ID"]
BUCKET     = os.environ["S3_BUCKET"]
REGION     = os.getenv("AWS_REGION", "ap-northeast-1")

# ------------------------------------------------------------------ #
# 2. 日付フォルダ決定 （JST）
# ------------------------------------------------------------------ #
today = datetime.datetime.now(
    datetime.timezone(datetime.timedelta(hours=9))
).strftime("%Y-%m-%d")

# ------------------------------------------------------------------ #
# 3. YouTube API で統計取得
# ------------------------------------------------------------------ #
youtube = build("youtube", "v3", developerKey=API_KEY)
resp = (
    youtube.channels()
    .list(id=CHANNEL_ID, part="statistics,snippet")
    .execute()
)
stats = resp["items"][0]["statistics"]   # viewCount, subscriberCount, ...
meta  = resp["items"][0]["snippet"]

row = {
    "date": today,
    "channel_id": CHANNEL_ID,
    "title": meta["title"],
    "viewCount": stats["viewCount"],
    "subscriberCount": stats["subscriberCount"],
    "videoCount": stats["videoCount"],
}

# ------------------------------------------------------------------ #
# 4. CSV 出力 (append or create)
# ------------------------------------------------------------------ #
out_dir = pathlib.Path("data/youtube_stats")
out_dir.mkdir(parents=True, exist_ok=True)
csv_path = out_dir / f"{today}.csv"

write_header = not csv_path.exists()
with open(csv_path, "a", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=row.keys())
    if write_header:
        writer.writeheader()
    writer.writerow(row)

print(f"[✓] CSV saved to {csv_path}")

# ------------------------------------------------------------------ #
# 5. S3 アップロード
# ------------------------------------------------------------------ #
s3_key = f"youtube/{today}.csv"
s3 = boto3.client("s3", region_name=REGION)
s3.upload_file(str(csv_path), BUCKET, s3_key)
print(f"[✓] Uploaded to s3://{BUCKET}/{s3_key}")