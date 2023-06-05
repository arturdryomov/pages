---
title: "Music Stats with DuckDB"
description: "Using DuckDB for ad-hoc SQL"
date: 2023-06-05
slug: music-stats-with-duckdb
---

Music! Everyone likes music. Well, I certainly hope so.
Stats! Well, not everyone likes stats but I certainly do.

In this article I’ll describe an approach to work with
[music scrobbles](https://en.wikipedia.org/wiki/Last.fm#Scrobbling)
from different sources and in different formats using [DuckDB](https://duckdb.org/).
DuckDB is a perfect match for such ad-hoc scenarios — it has a minimal
footprint, great performance and useful features.

# Scrobbles

I’ve been using multiple music sources over the past decade.
Fortunately, I had a [Last.fm](https://en.wikipedia.org/wiki/Last.fm) account from the beginning.
It allowed me to track almost everything I’ve listened — resulting in almost 110+ thousands of scrobbles.
Unfortunately, I haven’t used it all the time.

* 07.2008 — 03.2014: local music files
  * I’ve used various Linux music players with the Last.fm scrobbling enabled.
* 04.2014 — 09.2022: Spotify
  * [It is supported as a Last.fm scrobbling source](https://support.last.fm/t/spotify-scrobbling/189) but it wasn’t enabled for me until 04.2019.
* 10.2022 — now: [Bandcamp](https://bandcamp.com/), CDs
  * At this point I don’t track scrobbles but attempt to create a local music collection instead.

Last.fm seems to be a good source of truth for scrobbles but
its data is inconsistent due to the lack of scrobbling from Spotify for a period of time.
However, the complete data still can be assembled.

* Thanks to GDPR it’s possible to request the listening history from streaming services.
  See [steps for Spotify](https://support.stats.fm/docs/import/spotify-import/) and [for Apple Music](https://support.apple.com/en-us/HT208502).
* The Last.fm data retrieval is much easier — there is [a public API](https://www.last.fm/api/show/user.getRecentTracks).
  There are multiple online tools which call the API and prepare a combined report — that’s what I’ve used.

# DuckDB Import

## Spotify

There are 50+ files in the Spotify data export.
There is even a couple of documentation files — a welcome surprise.
The listening history is available at multiple `MyData/endsong_*.json` files.
Each JSON file has the following format.

```json
[
    {
        "ts": "2017-04-08T06:48:15Z",
        "username": "username",
        "platform": "unknown",
        "ms_played": 223646,
        "conn_country": "PL",
        "ip_addr_decrypted": "1.1.1.1",
        "user_agent_decrypted": "unknown",
        "master_metadata_track_name": "Good Man",
        "master_metadata_album_artist_name": "Raphael Saadiq",
        "master_metadata_album_album_name": "Stone Rollin'",
        "spotify_track_uri": "spotify:track:5jJOShacQWvCDHZgMhl8Zu",
        "episode_name": null,
        "episode_show_name": null,
        "spotify_episode_uri": null,
        "reason_start": "clickrow",
        "reason_end": "unknown",
        "shuffle": false,
        "skipped": null,
        "offline": false,
        "offline_timestamp": 0,
        "incognito_mode": false
    }
]
```

Besides merging podcasts and music in the same enumeration, the format is good.
It’s great for DuckDB since it can recognize JSON array items as rows and repeating JSON fields as columns.

> :bulb: Note that it’s possible to import multiple files using a file name mask.

```sql
CREATE TABLE scrobbles_spotify AS SELECT * FROM read_json_auto('MyData/endsong_*.json');
DESCRIBE scrobbles_spotify;
```
```
┌───────────────────────────────────┬─────────────┬─────────┬─────────┬─────────┬───────┐
│            column_name            │ column_type │  null   │   key   │ default │ extra │
│              varchar              │   varchar   │ varchar │ varchar │ varchar │ int32 │
├───────────────────────────────────┼─────────────┼─────────┼─────────┼─────────┼───────┤
│ ts                                │ TIMESTAMP   │ YES     │         │         │       │
│ username                          │ VARCHAR     │ YES     │         │         │       │
│ platform                          │ VARCHAR     │ YES     │         │         │       │
│ ms_played                         │ BIGINT      │ YES     │         │         │       │
│ conn_country                      │ VARCHAR     │ YES     │         │         │       │
│ ip_addr_decrypted                 │ VARCHAR     │ YES     │         │         │       │
│ user_agent_decrypted              │ VARCHAR     │ YES     │         │         │       │
│ master_metadata_track_name        │ VARCHAR     │ YES     │         │         │       │
│ master_metadata_album_artist_name │ VARCHAR     │ YES     │         │         │       │
│ master_metadata_album_album_name  │ VARCHAR     │ YES     │         │         │       │
│ spotify_track_uri                 │ VARCHAR     │ YES     │         │         │       │
│ episode_name                      │ VARCHAR     │ YES     │         │         │       │
│ episode_show_name                 │ VARCHAR     │ YES     │         │         │       │
│ spotify_episode_uri               │ VARCHAR     │ YES     │         │         │       │
│ reason_start                      │ VARCHAR     │ YES     │         │         │       │
│ reason_end                        │ VARCHAR     │ YES     │         │         │       │
│ shuffle                           │ BOOLEAN     │ YES     │         │         │       │
│ skipped                           │ BOOLEAN     │ YES     │         │         │       │
│ offline                           │ BOOLEAN     │ YES     │         │         │       │
│ offline_timestamp                 │ BIGINT      │ YES     │         │         │       │
│ incognito_mode                    │ BOOLEAN     │ YES     │         │         │       │
├───────────────────────────────────┴─────────────┴─────────┴─────────┴─────────┴───────┤
│ 21 rows                                                                     6 columns │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

Neat! Column types were recognized — even [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) time strings were recognized as `TIMESTAMP`.

## Last.fm

There is a single CSV file and its as simple as it gets.

```csv
uts,utc_time,artist,artist_mbid,album,album_mbid,track,track_mbid
"1667306723","01 Nov 2022, 12:45","How to Destroy Angels","143b396d-a678-43aa-8c74-628fea8e381f","How to Destroy Angels","4617ac46-8e11-4a14-9133-b00ecbae7069","Parasite","5aa91266-1d8b-3ede-bd97-ef4d5e921d4f"
```

> :bulb: `*_mbid` fields are [MusicBrainz](https://musicbrainz.org/) IDs.

A CSV file is essentially a table so there are no issues with the DuckDB import.

```sql
CREATE TABLE scrobbles_lastfm AS SELECT * FROM read_csv_auto('recenttracks.csv');
DESCRIBE scrobbles_lastfm;
```
```
┌─────────────┬─────────────┬─────────┬─────────┬─────────┬───────┐
│ column_name │ column_type │  null   │   key   │ default │ extra │
│   varchar   │   varchar   │ varchar │ varchar │ varchar │ int32 │
├─────────────┼─────────────┼─────────┼─────────┼─────────┼───────┤
│ uts         │ BIGINT      │ YES     │         │         │       │
│ utc_time    │ VARCHAR     │ YES     │         │         │       │
│ artist      │ VARCHAR     │ YES     │         │         │       │
│ artist_mbid │ VARCHAR     │ YES     │         │         │       │
│ album       │ VARCHAR     │ YES     │         │         │       │
│ album_mbid  │ VARCHAR     │ YES     │         │         │       │
│ track       │ VARCHAR     │ YES     │         │         │       │
│ track_mbid  │ VARCHAR     │ YES     │         │         │       │
└─────────────┴─────────────┴─────────┴─────────┴─────────┴───────┘
```

Unlike the Spotify import, the timestamp is not recognized out of the box.
This is not needed for steps below but it’s possible to specify the time format for a proper `TIMESTAMP` conversion.

```sql
SELECT utc_time, artist, track FROM read_csv_auto('recenttracks.csv', timestampformat='%d %b %Y, %H:%M') LIMIT 5;
```
```
┌─────────────────────┬───────────────────────┬──────────────────────┐
│      utc_time       │        artist         │        track         │
│      timestamp      │        varchar        │       varchar        │
├─────────────────────┼───────────────────────┼──────────────────────┤
│ 2021-11-01 12:45:00 │ How to Destroy Angels │ Parasite             │
│ 2021-11-01 12:41:00 │ How to Destroy Angels │ The Space in Between │
│ 2021-11-01 12:38:00 │ Karen Elson           │ We'll Meet Again     │
│ 2021-11-01 12:33:00 │ Karen Elson           │ Dancing On My Own    │
│ 2021-11-01 12:29:00 │ Karen Elson           │ Sacrifice            │
└─────────────────────┴───────────────────────┴──────────────────────┘
```

# DuckDB Queries

As a result of the successful import, there are two tables:

* `scrobbles_lastfm` — scrobbles from the Last.fm data export;
* `scrobbles_spotify` — scrobbles from the Spotify data export.

For a unified combined picture tables need to be merged with some adjustments:

* `scrobbles_lastfm` — nothing since [Last.fm is strict](https://www.last.fm/api/scrobbling#when-is-a-scrobble-a-scrobble) with incoming scrobbles;
* `scrobbles_spotify` — filter out doublicate scrobbles from Last.fm, incomplete and short scrobbles.

The resulting SQL is straightforward. This one in particular outputs scrobbles per album.

```sql
WITH
  scrobbles_spotify_ AS (
    SELECT
      master_metadata_track_name AS track,
      master_metadata_album_artist_name AS artist,
      master_metadata_album_album_name AS album
    FROM
      scrobbles_spotify
    WHERE
      -- Avoid scrobbles available at Last.fm
      ts BETWEEN TIMESTAMP '2014-04-01' AND TIMESTAMP '2019-03-31'
      -- Avoid short scrobbles
      AND ms_played > 30 * 1000
      -- Avoid incomplete scrobbles
      AND master_metadata_track_name IS NOT NULL
      AND master_metadata_album_artist_name IS NOT NULL
      AND master_metadata_album_album_name IS NOT NULL
  ),
  scrobbles AS (
    SELECT track, artist, album FROM scrobbles_lastfm
    UNION ALL
    SELECT track, artist, album FROM scrobbles_spotify_
  )

SELECT
  artist,
  album,
  COUNT(*) AS scrobbles_count
FROM
  scrobbles
GROUP BY
  artist, album
ORDER BY
  scrobbles_count DESC
LIMIT 5
```
```
┌───────────────────────────────┬───────────────────────────────┬─────────────────┐
│            artist             │             album             │ scrobbles_count │
│            varchar            │            varchar            │      int64      │
├───────────────────────────────┼───────────────────────────────┼─────────────────┤
│ Bonobo                        │ Black Sands                   │            1381 │
│ DJ Shadow                     │ The Private Press             │            1018 │
│ DJ Shadow                     │ The Less You Know, The Better │             920 │
│ The White Stripes             │ De Stijl                      │             796 │
│ Zero 7                        │ Simple Things                 │             787 │
├───────────────────────────────┴───────────────────────────────┴─────────────────┤
│ 5 rows                                                                3 columns │
└─────────────────────────────────────────────────────────────────────────────────┘
```

Since the resulting database can be treated as a regular SQL-compliant database,
it’s possible to do lots of things. For example:

* calculate stats per time interval, per artist, per album, per track and so on;
* export resulting stats [to JSON](https://duckdb.org/docs/guides/import/json_export.html) or
  [to CSV](https://duckdb.org/docs/guides/import/csv_export.html) and visualize them;
* combine stats with external data sources and create streaming / local playlists.

# Results

Doing this experiment was a fun excersize. I think that DuckDB might be a perfect tool
for ad-hoc analysis, especially when it comes to different data sources.
There is no need to set up a Trino cluster, pre-process data for a PostgreSQL import
or even to write a code at all — including pre-processing for Pandas / Polars.
Just import and run SQL, no strings attached.
