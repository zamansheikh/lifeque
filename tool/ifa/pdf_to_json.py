"""Convert Islamic Foundation Bangladesh's Ramadan PDFs into ifa/<year>.json.

    python3 tool/ifa/pdf_to_json.py <folder-with-division-pdfs> <hijri-year> <gregorian-year-of-day-1>
            [--order order.json]

Each PDF page is one district: Ramadan day, date, sahri end, Fajr azan,
iftar. The district name is printed in a legacy font that does not survive
text extraction, so pages are matched to districts by their times instead:
every page is compared with what each district's fitted edge points
(tool/ifa/districts.json) predict, and assigned to the closest. The mapping
is printed for checking; `--order` (a JSON of "file.pdf#page": "district-id")
overrides it.

Needs `pdftotext`/`pdfinfo` (poppler).
"""
import glob
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from sun import SunClock, local_seconds  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# Month names as they come out of the SutonnyMJ font.
MONTHS = [
    ('Rvbyqvwi', 1), ('deªæqvwi', 2), ('gvP©', 3), ('GwcÖj', 4), ('†g', 5), ('Ryb', 6),
    ('RyjvB', 7), ('AvM÷', 8), ('†m‡Þ¤^i', 9), ('A‡±vei', 10), ('b‡f¤^i', 11), ('wW‡m¤^i', 12),
]
ROW = re.compile(r'^\D*?(\d{2})\s+(\d{1,2})\s+(\S+).*?(\d{1,2}:\d{2})\s+(\d{1,2}:\d{2})\s+(\d{1,2}:\d{2})\s*$')


def month_of(word):
    for name, number in MONTHS:
        if name in word:
            return number
    raise ValueError(f'unknown month spelling: {word!r}')


def pages(pdf):
    info = subprocess.run(['pdfinfo', pdf], capture_output=True, text=True, check=True).stdout
    return int(re.search(r'Pages:\s+(\d+)', info).group(1))


def parse(folder, first_year):
    tables = {}
    for pdf in sorted(glob.glob(os.path.join(folder, '*.pdf'))):
        for page in range(1, pages(pdf) + 1):
            text = subprocess.run(['pdftotext', '-layout', '-f', str(page), '-l', str(page), pdf, '-'],
                                  capture_output=True, text=True, check=True).stdout
            rows, year, last_month = [], first_year, None
            for line in text.splitlines():
                m = ROW.match(line)
                if not m:
                    continue
                day, dom, month_word, sahri, fajr, iftar = m.groups()
                month = month_of(month_word)
                if last_month is not None and month < last_month:
                    year += 1  # December → January
                last_month = month

                def h24(t, pm):
                    h, mi = map(int, t.split(':'))
                    return f'{h + 12 if pm and h < 12 else h:02d}:{mi:02d}'
                rows.append([f'{year:04d}-{month:02d}-{int(dom):02d}', h24(sahri, False), h24(fajr, False),
                             h24(iftar, True), int(day)])
            if rows:
                tables[f'{os.path.basename(pdf)}#{page}'] = rows
    return tables


def predicted(district, date):
    y, m, d = map(int, date.split('-'))
    out = []
    for event in ('sahri', 'fajr', 'iftar'):
        lat, lon = district[event]
        sun = SunClock(lat, lon, y, m, d)
        out.append(local_seconds(sun.sunset() if event == 'iftar' else sun.fajr()))
    return out


def secs(hhmm):
    h, m = map(int, hhmm.split(':'))
    return h * 3600 + m * 60


def assign(tables, districts):
    """Greedy: the page/district pairs that agree best go first.

    Agreement is how many printed minutes the district's edge points
    reproduce exactly (sahri rounds down, Fajr and iftar up), then how close
    the rest come.
    """
    pairs = []
    for key, rows in tables.items():
        sample = rows[::3]
        for d in districts:
            misses, err = 0, 0.0
            for r in sample:
                p = predicted(d, r[0])
                for i in range(3):
                    o = secs(r[i + 1])
                    hit = (o <= p[i] < o + 60) if i == 0 else (o - 60 < p[i] <= o)
                    misses += not hit
                    err += abs(p[i] - (o + 30 if i == 0 else o - 30))
            pairs.append((misses, err, key, d['id']))
    pairs.sort()
    taken_pages, taken_ids, mapping = set(), set(), {}
    for _, _, key, did in pairs:
        if key in taken_pages or did in taken_ids:
            continue
        mapping[key] = did
        taken_pages.add(key)
        taken_ids.add(did)
    return mapping


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    folder, hijri_year, first_year = args[0], int(args[1]), int(args[2])
    order = None
    if '--order' in sys.argv:
        order = json.load(open(sys.argv[sys.argv.index('--order') + 1]))
    tables = parse(folder, first_year)
    districts = json.load(open(os.path.join(os.path.dirname(__file__), 'districts.json')))
    mapping = order or assign(tables, districts)
    names = {d['id']: d['bn'] for d in districts}
    for key in sorted(tables):
        print(f'{key:28s} → {mapping.get(key, "??"):16s} {names.get(mapping.get(key), "")}')

    out = {}
    for key, rows in tables.items():
        did = mapping[key]
        days = [r[4] for r in rows]
        if days != list(range(1, len(rows) + 1)) or len(rows) not in (29, 30):
            sys.exit(f'{key} ({did}): unexpected Ramadan days {days}')
        out[did] = [r[:4] for r in rows]
    missing = sorted(set(names) - set(out))
    if missing:
        sys.exit(f'missing districts: {missing}')

    doc = {
        'hijriYear': hijri_year,
        'source': 'Islamic Foundation Bangladesh — সাহরী-ইফতারের সময়সূচি, '
                  f'পবিত্র মাহে রমযান {hijri_year} হিজরী',
        'rule': 'Sahri: subh sadiq at the district\'s eastern edge, seconds dropped. '
                'Fajr azan: subh sadiq at the western edge, rounded up. '
                'Iftar: sunset at the western edge, rounded up.',
        'columns': ['date', 'sahri', 'fajr', 'iftar'],
        'districts': {k: out[k] for k in sorted(out)},
    }
    path = os.path.join(ROOT, 'ifa', f'{hijri_year}.json')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        json.dump(doc, f, ensure_ascii=False, separators=(',', ':'))
    print('wrote', os.path.relpath(path, ROOT), f'({len(out)} districts)')


if __name__ == '__main__':
    main()
