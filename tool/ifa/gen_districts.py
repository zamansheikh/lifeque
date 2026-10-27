"""Generate the district data behind the Islamic Foundation Ramadan option.

    python3 tool/ifa/gen_districts.py <geoBoundaries-BGD-ADM2.geojson> ifa/1447.json

For every district this finds the three points IFB's timetable behaves as if
it were computed at — sahri (eastern edge), Fajr azan and iftar (western
edge) — by fitting to an official year's tables, and simplifies the district
outline so the app can tell which district a GPS fix falls in.

Writes tool/ifa/districts.json and lib/features/ifa/ifa_districts.g.dart.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from sun import SunClock, local_seconds  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# id, English, Bangla, division id, geoBoundaries shapeName
DISTRICTS = [
    ('dhaka', 'Dhaka', 'ঢাকা', 'dhaka', 'Dhaka'),
    ('gazipur', 'Gazipur', 'গাজীপুর', 'dhaka', 'Gazipur'),
    ('narayanganj', 'Narayanganj', 'নারায়ণগঞ্জ', 'dhaka', 'Narayanganj'),
    ('narsingdi', 'Narsingdi', 'নরসিংদী', 'dhaka', 'Narsingdi'),
    ('munshiganj', 'Munshiganj', 'মুন্সীগঞ্জ', 'dhaka', 'Munshiganj'),
    ('manikganj', 'Manikganj', 'মানিকগঞ্জ', 'dhaka', 'Manikganj'),
    ('tangail', 'Tangail', 'টাঙ্গাইল', 'dhaka', 'Tangail'),
    ('kishoreganj', 'Kishoreganj', 'কিশোরগঞ্জ', 'dhaka', 'Kishoreganj'),
    ('faridpur', 'Faridpur', 'ফরিদপুর', 'dhaka', 'Faridpur'),
    ('rajbari', 'Rajbari', 'রাজবাড়ী', 'dhaka', 'Rajbari'),
    ('gopalganj', 'Gopalganj', 'গোপালগঞ্জ', 'dhaka', 'Gopalganj'),
    ('madaripur', 'Madaripur', 'মাদারীপুর', 'dhaka', 'Madaripur'),
    ('shariatpur', 'Shariatpur', 'শরীয়তপুর', 'dhaka', 'Shariatpur'),
    ('chattogram', 'Chattogram', 'চট্টগ্রাম', 'chattogram', 'Chittagong'),
    ('coxsbazar', "Cox's Bazar", 'কক্সবাজার', 'chattogram', "Cox's Bazar"),
    ('bandarban', 'Bandarban', 'বান্দরবান', 'chattogram', 'Bandarban'),
    ('rangamati', 'Rangamati', 'রাঙ্গামাটি', 'chattogram', 'Rangamati'),
    ('khagrachhari', 'Khagrachhari', 'খাগড়াছড়ি', 'chattogram', 'Khagrachhari'),
    ('feni', 'Feni', 'ফেনী', 'chattogram', 'Feni'),
    ('noakhali', 'Noakhali', 'নোয়াখালী', 'chattogram', 'Noakhali'),
    ('lakshmipur', 'Lakshmipur', 'লক্ষ্মীপুর', 'chattogram', 'Lakshmipur'),
    ('chandpur', 'Chandpur', 'চাঁদপুর', 'chattogram', 'Chandpur'),
    ('cumilla', 'Cumilla', 'কুমিল্লা', 'chattogram', 'Comilla'),
    ('brahmanbaria', 'Brahmanbaria', 'ব্রাহ্মণবাড়িয়া', 'chattogram', 'Brahamanbaria'),
    ('rajshahi', 'Rajshahi', 'রাজশাহী', 'rajshahi', 'Rajshahi'),
    ('chapainawabganj', 'Chapainawabganj', 'চাঁপাইনবাবগঞ্জ', 'rajshahi', 'Nawabganj'),
    ('naogaon', 'Naogaon', 'নওগাঁ', 'rajshahi', 'Naogaon'),
    ('natore', 'Natore', 'নাটোর', 'rajshahi', 'Natore'),
    ('bogura', 'Bogura', 'বগুড়া', 'rajshahi', 'Bogra'),
    ('joypurhat', 'Joypurhat', 'জয়পুরহাট', 'rajshahi', 'Joypurhat'),
    ('sirajganj', 'Sirajganj', 'সিরাজগঞ্জ', 'rajshahi', 'Sirajganj'),
    ('pabna', 'Pabna', 'পাবনা', 'rajshahi', 'Pabna'),
    ('khulna', 'Khulna', 'খুলনা', 'khulna', 'Khulna'),
    ('bagerhat', 'Bagerhat', 'বাগেরহাট', 'khulna', 'Bagerhat'),
    ('satkhira', 'Satkhira', 'সাতক্ষীরা', 'khulna', 'Satkhira'),
    ('jashore', 'Jashore', 'যশোর', 'khulna', 'Jessore'),
    ('narail', 'Narail', 'নড়াইল', 'khulna', 'Narail'),
    ('magura', 'Magura', 'মাগুরা', 'khulna', 'Magura'),
    ('jhenaidah', 'Jhenaidah', 'ঝিনাইদহ', 'khulna', 'Jhenaidah'),
    ('chuadanga', 'Chuadanga', 'চুয়াডাঙ্গা', 'khulna', 'Chuadanga'),
    ('meherpur', 'Meherpur', 'মেহেরপুর', 'khulna', 'Meherpur'),
    ('kushtia', 'Kushtia', 'কুষ্টিয়া', 'khulna', 'Kushtia'),
    ('barishal', 'Barishal', 'বরিশাল', 'barishal', 'Barisal'),
    ('bhola', 'Bhola', 'ভোলা', 'barishal', 'Bhola'),
    ('patuakhali', 'Patuakhali', 'পটুয়াখালী', 'barishal', 'Patuakhali'),
    ('barguna', 'Barguna', 'বরগুনা', 'barishal', 'Barguna'),
    ('pirojpur', 'Pirojpur', 'পিরোজপুর', 'barishal', 'Pirojpur'),
    ('jhalokati', 'Jhalokati', 'ঝালকাঠি', 'barishal', 'Jhalokati'),
    ('sylhet', 'Sylhet', 'সিলেট', 'sylhet', 'Sylhet'),
    ('moulvibazar', 'Moulvibazar', 'মৌলভীবাজার', 'sylhet', 'Maulvibazar'),
    ('habiganj', 'Habiganj', 'হবিগঞ্জ', 'sylhet', 'Habiganj'),
    ('sunamganj', 'Sunamganj', 'সুনামগঞ্জ', 'sylhet', 'Sunamganj'),
    ('rangpur', 'Rangpur', 'রংপুর', 'rangpur', 'Rangpur'),
    ('dinajpur', 'Dinajpur', 'দিনাজপুর', 'rangpur', 'Dinajpur'),
    ('thakurgaon', 'Thakurgaon', 'ঠাকুরগাঁও', 'rangpur', 'Thakurgaon'),
    ('panchagarh', 'Panchagarh', 'পঞ্চগড়', 'rangpur', 'Panchagarh'),
    ('nilphamari', 'Nilphamari', 'নীলফামারী', 'rangpur', 'Nilphamari'),
    ('lalmonirhat', 'Lalmonirhat', 'লালমনিরহাট', 'rangpur', 'Lalmonirhat'),
    ('kurigram', 'Kurigram', 'কুড়িগ্রাম', 'rangpur', 'Kurigram'),
    ('gaibandha', 'Gaibandha', 'গাইবান্ধা', 'rangpur', 'Gaibandha'),
    ('mymensingh', 'Mymensingh', 'ময়মনসিংহ', 'mymensingh', 'Mymensingh'),
    ('jamalpur', 'Jamalpur', 'জামালপুর', 'mymensingh', 'Jamalpur'),
    ('sherpur', 'Sherpur', 'শেরপুর', 'mymensingh', 'Sherpur'),
    ('netrokona', 'Netrokona', 'নেত্রকোনা', 'mymensingh', 'Netrakona'),
]


# ── Outlines ────────────────────────────────────────────────────────────────

def _perp(p, a, b):
    if a == b:
        return math.dist(p, a)
    (x, y), (x1, y1), (x2, y2) = p, a, b
    return abs((y2 - y1) * x - (x2 - x1) * y + x2 * y1 - y2 * x1) / math.dist(a, b)


def simplify(points, tol):
    """Douglas–Peucker."""
    if len(points) < 3:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        s, e = stack.pop()
        best, idx = 0.0, None
        for i in range(s + 1, e):
            d = _perp(points[i], points[s], points[e])
            if d > best:
                best, idx = d, i
        if idx is not None and best > tol:
            keep[idx] = True
            stack += [(s, idx), (idx, e)]
    return [p for p, k in zip(points, keep) if k]


def area(ring):
    return abs(sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(ring, ring[1:] + ring[:1]))) / 2


def outlines(geom):
    polys = geom['coordinates'] if geom['type'] == 'MultiPolygon' else [geom['coordinates']]
    rings = [poly[0] for poly in polys]  # outer rings; holes don't matter here
    biggest = max(area(r) for r in rings)
    kept = [simplify(r, 0.02) for r in rings if area(r) >= biggest * 0.02]
    return [r for r in kept if len(r) >= 4]


# ── Fitting ─────────────────────────────────────────────────────────────────

def _secs(hhmm):
    h, m = map(int, hhmm.split(':'))
    return h * 3600 + m * 60


def _event_seconds(event, lat, lon, date):
    y, m, d = map(int, date.split('-'))
    sun = SunClock(lat, lon, y, m, d)
    minutes = sun.sunset() if event == 'iftar' else sun.fajr()
    return local_seconds(minutes)


def fit(rows, event, ref, lat_range):
    """The (lat, lon) whose times reproduce [rows] for [event] best.

    Moving a point west delays every event by 240 s per degree, so for each
    latitude the feasible longitudes form one window; the widest window wins,
    and its middle is the most robust choice for other years.
    """
    col = {'sahri': 1, 'fajr': 2, 'iftar': 3}[event]
    floor = event == 'sahri'
    lat_lo, lat_hi = lat_range
    best = None
    lat = lat_lo - 0.02
    while lat <= lat_hi + 0.02:
        samples = [(_event_seconds(event, lat, ref[0], r[0]), _secs(r[col])) for r in rows]
        lo, hi = -1e9, 1e9
        for t, o in samples:
            if floor:
                lo, hi = max(lo, o - t), min(hi, o + 60 - t)
            else:
                lo, hi = max(lo, o - 60 - t), min(hi, o - t)
        if hi > lo:
            key = (hi - lo, -abs(lat - ref[1]))
            if best is None or key > best[0]:
                best = (key, lat, (lo + hi) / 2, len(rows))
        else:
            # No exact window: take the shift that matches the most days.
            for shift in range(-600, 601, 2):
                ok = sum((o <= t + shift < o + 60) if floor else (o - 60 < t + shift <= o)
                         for t, o in samples)
                key = (ok - len(rows) - 100, -abs(lat - ref[1]))  # always below any exact fit
                if best is None or key > best[0]:
                    best = (key, lat, shift, ok)
        lat += 0.01
    _, lat, shift, matched = best
    return round(lat, 4), round(ref[0] - shift / 240.0, 4), matched


def main(geojson_path, table_path):
    geo = {f['properties']['shapeName']: f['geometry'] for f in json.load(open(geojson_path))['features']}
    table = json.load(open(table_path))
    out = []
    total = exact = 0
    for did, en, bn, div, shape in DISTRICTS:
        geom = geo[shape]
        polys = geom['coordinates'] if geom['type'] == 'MultiPolygon' else [geom['coordinates']]
        pts = [p for poly in polys for ring in poly for p in ring]
        lats = (min(p[1] for p in pts), max(p[1] for p in pts))
        east = max(pts, key=lambda p: p[0])
        west = min(pts, key=lambda p: p[0])
        rows = table['districts'][did]
        rec = dict(id=did, en=en, bn=bn, division=div, outline=outlines(geom))
        for event, ref in (('sahri', east), ('fajr', west), ('iftar', west)):
            lat, lon, matched = fit(rows, event, ref, lats)
            rec[event] = [lat, lon]
            total += len(rows)
            exact += matched
        out.append(rec)
        print(f"{did:16s} sahri {rec['sahri']} fajr {rec['fajr']} iftar {rec['iftar']}")
    print(f'fitted: {exact}/{total} values reproduce {table["hijriYear"]} exactly')

    json.dump(out, open(os.path.join(os.path.dirname(__file__), 'districts.json'), 'w'),
              ensure_ascii=False, indent=1)
    write_dart(out, table['hijriYear'])


def write_dart(districts, year):
    lines = [
        '// GENERATED by tool/ifa/gen_districts.py — do not edit by hand.',
        '//',
        '// Outlines: geoBoundaries gbOpen BGD ADM2 (Bangladesh Bureau of',
        '// Statistics, OCHA ROAP), CC BY 3.0 IGO, simplified. Edge points fitted',
        f'// to Islamic Foundation Bangladesh\'s Ramadan {year} AH tables.',
        '',
        "part of 'ifa_district.dart';",
        '',
        'const ifaDistricts = <IfaDistrict>[',
    ]
    for d in districts:
        rings = ', '.join(
            '[' + ', '.join(f'{p[1]:.4f}, {p[0]:.4f}' for p in ring) + ']' for ring in d['outline'])
        lines += [
            '  IfaDistrict(',
            f"    id: '{d['id']}',",
            f"    en: \"{d['en']}\",",
            f"    bn: '{d['bn']}',",
            f"    division: '{d['division']}',",
            f"    sahri: ({d['sahri'][0]}, {d['sahri'][1]}),",
            f"    fajr: ({d['fajr'][0]}, {d['fajr'][1]}),",
            f"    iftar: ({d['iftar'][0]}, {d['iftar'][1]}),",
            f'    outline: [{rings}],',
            '  ),',
        ]
    lines += ['];', '']
    path = os.path.join(ROOT, 'lib', 'features', 'ifa', 'ifa_districts.g.dart')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write('\n'.join(lines))
    print('wrote', os.path.relpath(path, ROOT))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
