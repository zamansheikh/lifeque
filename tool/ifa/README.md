# Islamic Foundation Ramadan timetable

The app's "ইসলামিক ফাউন্ডেশনের রমজান ক্যালেন্ডার" option shows sahri, Fajr azan
and iftar as Islamic Foundation Bangladesh (IFB) publishes them: one table per
district, per Ramadan.

## Every year, when IFB publishes the new Ramadan calendar

1. Download the eight division PDFs (IFB posts them; newspapers such as
   Prothom Alo link the same files) into one folder.
2. Convert them:

       python3 tool/ifa/pdf_to_json.py <folder-with-pdfs> <hijri-year>

   It writes `ifa/<hijri-year>.json`, prints the district each page was matched
   to (check it), and fails if any district is missing or any row is odd.
3. Commit and push `ifa/<hijri-year>.json`. Installed apps download it from
   `https://raw.githubusercontent.com/zamansheikh/lifeque/main/ifa/<year>.json`
   — no app release needed.

Until a year's table exists the app computes the times by IFB's own published
rule (sahri: subh sadiq at the district's eastern edge, seconds dropped; Fajr
azan: subh sadiq at the western edge, rounded up; iftar: sunset at the western
edge, rounded up), at the edge points fitted to the 1447 tables. Against the
1447 tables that reproduces ~94% of values exactly and the rest within a minute.

## Regenerating the district data

    python3 tool/ifa/gen_districts.py <geoBoundaries-BGD-ADM2.geojson> ifa/1447.json

writes `lib/features/ifa/ifa_districts.g.dart`. Boundaries: geoBoundaries
gbOpen BGD ADM2 (Bangladesh Bureau of Statistics / OCHA ROAP),
CC BY 3.0 IGO.
