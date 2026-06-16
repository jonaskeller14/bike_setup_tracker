"""Generates lightweight .fit activity files for Strava bulk upload.

One activity per setup in the May 2026 sample dataset (matching location + date),
so the Strava data lines up with the in-app sample data.

Only the fields the app uses are crafted to be meaningful:
  - start lat/lon            (record stream + session start_position_*)
  - distance                 (explicit record 'distance' field + session total_distance)
  - elevation gain           (record 'altitude' stream + session total_ascent)
  - moving / elapsed time    (record timestamps + session total_timer/elapsed_time)

A real GPS route is NOT required: positions follow a simple straight line of the
target length so Strava's GPS-derived distance also matches the explicit distance.

Pure standard library - implements a minimal FIT encoder (no external deps).
"""
import json
import os
import struct
from datetime import datetime, timezone

SRC = "20260614_sample.json"
OUT_DIR = "strava_fit"

FIT_EPOCH = 631065600          # unix seconds at 1989-12-31T00:00:00Z
SEMI = 2 ** 31 / 180.0         # degrees -> semicircles
M_PER_DEG_LAT = 111320.0

# ---- FIT base types --------------------------------------------------------- #
ENUM, UINT8, UINT16, SINT32, UINT32, UINT16Z, UINT32Z = 0x00, 0x02, 0x84, 0x85, 0x86, 0x8B, 0x8C
SIZE = {ENUM: 1, UINT8: 1, UINT16: 2, UINT16Z: 2, SINT32: 4, UINT32: 4, UINT32Z: 4}
FMT = {ENUM: "<B", UINT8: "<B", UINT16: "<H", UINT16Z: "<H", SINT32: "<i", UINT32: "<I", UINT32Z: "<I"}

# global message numbers
MSG_FILE_ID, MSG_SESSION, MSG_LAP, MSG_RECORD, MSG_ACTIVITY = 0, 18, 19, 20, 34


def fit_crc(data, crc=0):
    table = [0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
             0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400]
    for b in data:
        tmp = table[crc & 0xF]
        crc = ((crc >> 4) & 0x0FFF) ^ tmp ^ table[b & 0xF]
        tmp = table[crc & 0xF]
        crc = ((crc >> 4) & 0x0FFF) ^ tmp ^ table[(b >> 4) & 0xF]
    return crc & 0xFFFF


def semicircles(deg):
    return int(round(deg * SEMI))


def fit_ts(unix_seconds):
    return int(unix_seconds - FIT_EPOCH)


class FitWriter:
    def __init__(self):
        self.body = bytearray()

    def definition(self, local_type, global_num, fields):
        b = bytearray([0x40 | local_type, 0x00, 0x00])
        b += struct.pack("<H", global_num)
        b.append(len(fields))
        for fdn, base in fields:
            b += bytes([fdn, SIZE[base], base])
        self.body += b

    def data(self, local_type, fields, values):
        b = bytearray([local_type])
        for (_, base), val in zip(fields, values):
            b += struct.pack(FMT[base], val)
        self.body += b

    def build(self):
        data_size = len(self.body)
        header = bytearray([14, 0x20]) + struct.pack("<H", 2132) + struct.pack("<I", data_size) + b".FIT"
        header += struct.pack("<H", fit_crc(header))
        full = bytes(header) + bytes(self.body)
        return full + struct.pack("<H", fit_crc(full))


# ---- field layouts ---------------------------------------------------------- #
F_FILE_ID = [(0, ENUM), (1, UINT16), (2, UINT16), (3, UINT32Z), (4, UINT32)]
F_RECORD = [(253, UINT32), (0, SINT32), (1, SINT32), (2, UINT16), (5, UINT32)]
F_LAP = [(253, UINT32), (2, UINT32), (3, SINT32), (4, SINT32),
         (7, UINT32), (8, UINT32), (9, UINT32), (21, UINT16)]
F_SESSION = [(253, UINT32), (2, UINT32), (3, SINT32), (4, SINT32), (5, ENUM), (6, ENUM),
             (7, UINT32), (8, UINT32), (9, UINT32), (22, UINT16)]
F_ACTIVITY = [(253, UINT32), (1, UINT16), (2, ENUM), (0, UINT32), (5, UINT32)]

L_FILE_ID, L_RECORD, L_LAP, L_SESSION, L_ACTIVITY = 0, 1, 2, 3, 4


def make_fit(start_lat, start_lng, base_alt, dist_m, ascent_m,
             moving_s, elapsed_s, start_unix, tz_offset=7200):
    n = min(250, max(20, elapsed_s // 60))
    w = FitWriter()

    # file_id (type=activity, manufacturer=garmin(1), product=Edge 530(3121) w/ baro)
    w.definition(L_FILE_ID, MSG_FILE_ID, F_FILE_ID)
    w.data(L_FILE_ID, F_FILE_ID, [4, 1, 3121, 0xFFFFFFFF, fit_ts(start_unix)])

    # record stream
    w.definition(L_RECORD, MSG_RECORD, F_RECORD)
    end_unix = start_unix + elapsed_s
    for i in range(n):
        frac = i / (n - 1)
        ts = fit_ts(start_unix + round(elapsed_s * frac))
        d = dist_m * frac
        lat = start_lat + (d / M_PER_DEG_LAT)
        # single climb (up to 60%) then descent -> positive deltas sum to ascent_m
        if frac <= 0.6:
            alt = base_alt + ascent_m * (frac / 0.6)
        else:
            alt = base_alt + ascent_m * (1 - (frac - 0.6) / 0.4)
        alt_raw = int(round((alt + 500) * 5))
        w.data(L_RECORD, F_RECORD,
               [ts, semicircles(lat), semicircles(start_lng), alt_raw, int(round(d * 100))])

    # lap + session summaries
    w.definition(L_LAP, MSG_LAP, F_LAP)
    w.data(L_LAP, F_LAP, [fit_ts(end_unix), fit_ts(start_unix),
                          semicircles(start_lat), semicircles(start_lng),
                          elapsed_s * 1000, moving_s * 1000,
                          int(round(dist_m * 100)), int(round(ascent_m))])

    w.definition(L_SESSION, MSG_SESSION, F_SESSION)
    w.data(L_SESSION, F_SESSION, [fit_ts(end_unix), fit_ts(start_unix),
                                  semicircles(start_lat), semicircles(start_lng),
                                  2, 0,  # sport=cycling, sub_sport=generic
                                  elapsed_s * 1000, moving_s * 1000,
                                  int(round(dist_m * 100)), int(round(ascent_m))])

    w.definition(L_ACTIVITY, MSG_ACTIVITY, F_ACTIVITY)
    w.data(L_ACTIVITY, F_ACTIVITY, [fit_ts(end_unix), 1, 0,
                                    moving_s * 1000, fit_ts(start_unix) + tz_offset])
    return w.build()


# ---- per-setup activity stats: (distance_km, ascent_m, moving_min, elapsed_min) -- #
STATS = {
    "Hometrails - Season Opener":          (24, 720, 95, 150),
    "Bikepark Winterberg":                 (18, 380, 75, 300),
    "Hometrails - post fork service":      (21, 640, 80, 120),
    "Saalbach - Big Day Out":              (42, 1950, 165, 260),
    "Saalbach - Hacklberg & Pro Line":     (38, 1700, 150, 240),
    "Flowtrail Stromberg":                 (16, 320, 55, 110),
    "Leogang - Worldcup Track (wet)":      (15, 300, 60, 280),
    "Leogang - Speedster (dry)":           (22, 460, 85, 300),
    "Mia - Hometrails":                    (19, 560, 78, 120),
    "Bikepark Lac Blanc":                  (20, 520, 80, 260),
    "Finale Ligure - NATO Trail":          (28, 900, 110, 240),
    "Finale Ligure - DH Men":              (24, 780, 100, 220),
    "Finale - eMTB explore day":           (45, 2100, 180, 280),
    "Gravel - Kaiserstuhl Loop":           (86, 640, 210, 250),
    "Mia - Bikepark Willingen":            (17, 360, 70, 290),
    "Hometrails - end of May reference":   (23, 700, 90, 140),
}


def slug(s):
    return "".join(c.lower() if c.isalnum() else "-" for c in s).strip("-").replace("--", "-")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    data = json.load(open(SRC, encoding="utf-8"))
    setups = sorted(data["setups"], key=lambda s: s["datetime"])
    summary = []
    for s in setups:
        if s["name"] not in STATS:
            continue
        km, asc, mov_min, ela_min = STATS[s["name"]]
        pos = s["position"] or {}
        lat = pos.get("latitude", 48.0)
        lng = pos.get("longitude", 9.0)
        alt = pos.get("altitude") or 300.0
        # end the ride at the setup's logged time -> start = setup_time - elapsed
        end_dt = datetime.fromisoformat(s["datetime"].replace("Z", "+00:00")).astimezone(timezone.utc)
        elapsed_s = ela_min * 60
        start_unix = int(end_dt.timestamp()) - elapsed_s
        fit = make_fit(lat, lng, float(alt), km * 1000.0, asc,
                       mov_min * 60, elapsed_s, start_unix)
        date = s["datetimeLocal"][:10]
        fname = f"{date.replace('-', '')}_{slug(s['name'])}.fit"
        with open(os.path.join(OUT_DIR, fname), "wb") as f:
            f.write(fit)
        summary.append((fname, km, asc, mov_min, len(fit)))

    print(f"Wrote {len(summary)} .fit files to {OUT_DIR}/")
    for fname, km, asc, mov, size in summary:
        print(f"  {fname:<46} {km:>3} km  {asc:>5} hm  {mov:>3} min  ({size} B)")


if __name__ == "__main__":
    main()
