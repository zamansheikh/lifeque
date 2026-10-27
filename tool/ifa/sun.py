"""Python twin of lib/core/utils/sun_clock.dart (NOAA solar equations).

Kept line-for-line equivalent so that edge points fitted here mean exactly
the same thing in the app. Times are minutes after 00:00 UTC of the date.
"""
import math

D2R = math.pi / 180
R2D = 180 / math.pi


def julian_day(y, m, d):
    if m <= 2:
        y -= 1
        m += 12
    a = y // 100
    b = 2 - a + a // 4
    return math.floor(365.25 * (y + 4716)) + math.floor(30.6001 * (m + 1)) + d + b - 1524.5


class SunClock:
    def __init__(self, lat, lon, y, m, d):
        self.lat, self.lon = lat, lon
        self.jd0 = julian_day(y, m, d)
        self._transit = None

    def _sun(self, minutes):
        t = (self.jd0 + minutes / 1440 - 2451545.0) / 36525.0
        l0 = (280.46646 + t * (36000.76983 + 0.0003032 * t)) % 360
        m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        mr = m * D2R
        center = (math.sin(mr) * (1.914602 - t * (0.004817 + 0.000014 * t))
                  + math.sin(2 * mr) * (0.019993 - 0.000101 * t)
                  + math.sin(3 * mr) * 0.000289)
        omega = (125.04 - 1934.136 * t) * D2R
        lam = l0 + center - 0.00569 - 0.00478 * math.sin(omega)
        mean_obl = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        obl = mean_obl + 0.00256 * math.cos(omega)
        decl = math.asin(math.sin(obl * D2R) * math.sin(lam * D2R)) * R2D
        y = math.tan(obl * D2R / 2) ** 2
        l0r = l0 * D2R
        eot = 4 * R2D * (y * math.sin(2 * l0r) - 2 * e * math.sin(mr)
                         + 4 * e * y * math.sin(mr) * math.cos(2 * l0r)
                         - 0.5 * y * y * math.sin(4 * l0r) - 1.25 * e * e * math.sin(2 * mr))
        return decl, eot

    def geometric_altitude(self, minutes):
        decl, eot = self._sun(minutes)
        hour_angle = (minutes + eot + 4 * self.lon) / 4 - 180
        la, de = self.lat * D2R, decl * D2R
        c = math.sin(la) * math.sin(de) + math.cos(la) * math.cos(de) * math.cos(hour_angle * D2R)
        return 90 - math.acos(max(-1.0, min(1.0, c))) * R2D

    @staticmethod
    def refraction(alt):
        if alt > 85:
            return 0.0
        t = math.tan(alt * D2R)
        if alt > 5:
            arcsec = 58.1 / t - 0.07 / t ** 3 + 0.000086 / t ** 5
        elif alt > -0.575:
            arcsec = 1735 + alt * (-518.2 + alt * (103.4 + alt * (-12.79 + alt * 0.711)))
        else:
            arcsec = -20.772 / t
        return arcsec / 3600

    def apparent_altitude(self, minutes):
        g = self.geometric_altitude(minutes)
        return g + self.refraction(g)

    @property
    def transit(self):
        if self._transit is None:
            m = 720 - 4 * self.lon
            for _ in range(3):
                m = 720 - 4 * self.lon - self._sun(m)[1]
            self._transit = m
        return self._transit

    def minutes_at(self, altitude, morning, apparent=True):
        alt = self.apparent_altitude if apparent else self.geometric_altitude
        noon = self.transit
        lo, hi = (noon - 720, noon) if morning else (noon, noon + 720)
        a_lo, a_hi = alt(lo), alt(hi)
        lowest, highest = (a_lo, a_hi) if morning else (a_hi, a_lo)
        if altitude < lowest or altitude > highest:
            return None
        for _ in range(60):
            mid = (lo + hi) / 2
            above = alt(mid) >= altitude
            if above == morning:
                hi = mid
            else:
                lo = mid
        return (lo + hi) / 2

    def fajr(self, angle=18.0):
        return self.minutes_at(-angle, True)

    def sunset(self):
        return self.minutes_at(-0.833, False, apparent=False)


BD_OFFSET_MIN = 6 * 60  # Asia/Dhaka, no DST


def local_seconds(utc_minutes):
    """Seconds after local midnight in Bangladesh."""
    return (utc_minutes + BD_OFFSET_MIN) * 60
