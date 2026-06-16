"""Generates .gpx activity files from a JSON manifest, one per activity.

Usage:
    python 20260614_strava_gpx.py [input.json] [output_dir]

Strava derives distance, elevation gain and elapsed/moving time from the
trackpoints (GPX has no summary fields). Points follow a straight line of the
target length with a single stationary break so moving time < elapsed time.
"""
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from xml.sax.saxutils import escape

SRC = "20260614_strava_activities.json"
OUT_DIR = "20260614_strava_gpx"

M_PER_DEG_LAT = 111320.0
BREAK_FRACTION = 0.55


def slug(s):
    return "".join(c.lower() if c.isalnum() else "-" for c in s).strip("-").replace("--", "-")


def altitude(dist_frac, base_alt, ascent_m):
    # climb up to 60% of the distance, then descend, so positive deltas == ascent_m
    if dist_frac <= 0.6:
        return base_alt + ascent_m * (dist_frac / 0.6)
    return base_alt + ascent_m * (1 - (dist_frac - 0.6) / 0.4)


def samples(dist_m, moving_s, elapsed_s):
    # (seconds_from_start, metres_travelled): ride, hold for the pause, ride on
    pause_s = max(0, elapsed_s - moving_s)
    fb = BREAK_FRACTION
    n_move = max(15, min(200, moving_s // 60))
    n_a = max(2, round(n_move * fb))
    n_b = max(2, n_move - n_a)
    n_break = 0 if pause_s <= 0 else max(2, min(60, pause_s // 120))

    pts = []
    for i in range(n_a):
        f = i / (n_a - 1)
        pts.append((f * fb * moving_s, f * fb * dist_m))
    for j in range(1, n_break + 1):
        f = j / n_break
        pts.append((fb * moving_s + f * pause_s, fb * dist_m))
    base_t = fb * moving_s + pause_s
    for i in range(1, n_b):
        f = i / (n_b - 1)
        pts.append((base_t + f * (1 - fb) * moving_s, fb * dist_m + f * (1 - fb) * dist_m))
    return pts


def make_gpx(act):
    title = escape(act["name"])
    lat0 = act["lat"] if act["lat"] is not None else 48.0
    lon0 = act["lon"] if act["lon"] is not None else 9.0
    base_alt = float(act.get("alt") or 300.0)
    dist_m = act["distanceKm"] * 1000.0
    ascent_m = float(act["ascentM"])
    moving_s = act["movingMin"] * 60
    elapsed_s = act["elapsedMin"] * 60
    start = datetime.fromisoformat(act["startUtc"].replace("Z", "+00:00")).astimezone(timezone.utc)

    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<gpx version="1.1" creator="bike_setup_tracker sample generator"',
        '     xmlns="http://www.topografix.com/GPX/1/1"',
        '     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
        '     xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
        'http://www.topografix.com/GPX/1/1/gpx.xsd">',
        '  <metadata>',
        f'    <name>{title}</name>',
        f'    <time>{start.strftime("%Y-%m-%dT%H:%M:%SZ")}</time>',
        '  </metadata>',
        '  <trk>',
        f'    <name>{title}</name>',
        '    <trkseg>',
    ]
    for t_s, d_m in samples(dist_m, moving_s, elapsed_s):
        lat = lat0 + d_m / M_PER_DEG_LAT
        ele = altitude(d_m / dist_m if dist_m else 0.0, base_alt, ascent_m)
        ts = (start + timedelta(seconds=round(t_s))).strftime("%Y-%m-%dT%H:%M:%SZ")
        lines.append(
            f'      <trkpt lat="{lat:.6f}" lon="{lon0:.6f}">'
            f'<ele>{ele:.1f}</ele><time>{ts}</time></trkpt>'
        )
    lines += ['    </trkseg>', '  </trk>', '</gpx>', '']
    return "\n".join(lines)


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else SRC
    out_dir = sys.argv[2] if len(sys.argv) > 2 else OUT_DIR
    os.makedirs(out_dir, exist_ok=True)
    activities = json.load(open(src, encoding="utf-8"))["activities"]

    for act in activities:
        fname = f"{act['startUtc'][:10].replace('-', '')}_{slug(act['name'])}.gpx"
        with open(os.path.join(out_dir, fname), "w", encoding="utf-8") as f:
            f.write(make_gpx(act))

    print(f"Wrote {len(activities)} .gpx files to {out_dir}/")


if __name__ == "__main__":
    main()
