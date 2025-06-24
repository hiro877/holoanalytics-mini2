{{ config(materialized='table') }}

WITH base AS (
    SELECT
        date,
        channel_id,
        view_count,
        subscriber_count,
        video_count,
        LAG(view_count)       OVER (PARTITION BY channel_id ORDER BY date) AS prev_views,
        LAG(subscriber_count) OVER (PARTITION BY channel_id ORDER BY date) AS prev_subs
    FROM {{ ref('stg_youtube_stats') }}
)

SELECT
    date,
    channel_id,
    -- 当日差分
    view_count       - COALESCE(prev_views, 0) AS views_daily,
    subscriber_count - COALESCE(prev_subs, 0) AS subs_daily,
    -- 累計
    view_count,
    subscriber_count,
    video_count
FROM base