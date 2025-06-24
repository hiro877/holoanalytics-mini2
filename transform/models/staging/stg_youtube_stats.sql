{{ config(materialized='view') }}

WITH source AS (
    SELECT
        `date`,
        channel_id,
        title,
        viewCount       AS view_count,
        subscriberCount AS subscriber_count,
        videoCount      AS video_count
    FROM raw.youtube_stats
)

SELECT
    {{ date_trunc_mysql('day', '`date`') }}  AS date,
    channel_id,
    title,
    CAST(view_count       AS UNSIGNED)  AS view_count,
    CAST(subscriber_count AS UNSIGNED)  AS subscriber_count,
    CAST(video_count      AS UNSIGNED)  AS video_count
FROM source