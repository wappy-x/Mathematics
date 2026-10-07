# Trig graphs -- the check behind the card.  Standard library only.  A tide
# table is read into y = a sin(b(t - c)) + d by the reading rules (road one).
# Road two builds that curve, samples it once a minute and measures it back:
# highs, lows, midline crossings, the shortest repeat.  It must return the table.
import math
table = [(4.1, 3.5), (10.3, 0.5), (16.5, 3.5), (22.7, 0.5)]   # (hours after midnight, m)
(t1, hi), (_, lo), (t3, _), _ = table
a, d = (hi - lo) / 2, (hi + lo) / 2     # road one: half the swing, and the middle of it
P = t3 - t1                             # high water to high water
b = 2 * math.pi / P                     # one full turn, 2 pi radians, per period
c = t1 - P / 4                          # the sine starts rising a quarter period before its peak
wave = lambda a, b, c, d: lambda t: a * math.sin(b * (t - c)) + d
y = wave(a, b, c, d)
hm = lambda t: f"{round(t * 60) // 60:02d}:{round(t * 60) % 60:02d}"

def extremes(f, s):                     # road two: highs (s = 1) or lows (s = -1), minute by minute
    v = [s * f(m / 60) for m in range(1441)]
    return [(m / 60, s * v[m]) for m in range(1, 1440) if v[m - 1] < v[m] >= v[m + 1]]
def pin(f, level, l, h):                # bisection: halve the bracket 60 times
    for _ in range(60):
        l, h = ((l + h) / 2, h) if f((l + h) / 2) < level else (l, (l + h) / 2)
    return h
def rising(f, level):                   # road two: where f climbs through level, found by the minute, then pinned
    return [pin(f, level, (m - 1) / 60, m / 60) for m in range(1, 1441) if f((m - 1) / 60) < level <= f(m / 60)]
def shortest_repeat(f):                 # road two: the first shift, in steps of 0.01 h, that repeats f
    return next((k / 100 for k in range(1, 2001)
                 if max(abs(f(t + k / 100) - f(t)) for t in range(25)) < 1e-9), math.inf)

highs, lows = extremes(y, 1), extremes(y, -1)
mid = (highs[0][1] + lows[0][1]) / 2    # the midline as measured, not as read
ups, downs, rep = rising(y, mid), rising(lambda t: -y(t), -mid), shortest_repeat(y)
forms = [lambda t: a * math.cos(b * (t - t1)) + d, wave(a, b, c + P, d), wave(-a, b, c + P / 2, d)]
gap = max(abs(f(t) - y(t)) for f in forms for t in range(25))
at = lambda pts: ", ".join(f"{v:.1f} m at {hm(t)}" for t, v in pts)
print("tide table: " + at(table))
print(f"road 1, reading rules: swing {hi - lo:.1f} m, a = {a:.1f} m, d = {d:.1f} m, P = {P:.1f} h ({hm(P)}), P/4 = {P / 4:.1f} h, c = {c:.1f} h ({hm(c)})")
print(f"road 1: b = 2 pi / {P:.1f} = {b:.4f} radians per hour = {math.degrees(b):.2f} degrees per hour")
print(f"road 2, measured off the curve: highs {at(highs)}; lows {at(lows)}; midline {mid:.1f} m")
print(f"road 2, midline crossings: rising {', '.join(map(hm, ups))}; falling {', '.join(map(hm, downs))}")
print(f"road 2, shortest shift that repeats the curve, tried in steps of 0.01 h: {rep:.2f} h")
print(f"cosine from {hm(t1)}, sine from {hm(c + P)}, sine with a = {-a:.1f} from {hm(c + P / 2)}: all agree: {'yes' if gap < 1e-12 else 'no'}")
print(f"height at 09:00: angle {b * (9 - c):.4f} rad, sine {math.sin(b * (9 - c)):.4f}, height {y(9):.2f} m")
print(f"tomorrow's first high water: {hm(t1 + 2 * P - 24)}, {round((2 * P - 24) * 60)} min later")
sw = wave(hi - lo, b, c, d)
print(f"mistake, swing as amplitude: highs {extremes(sw, 1)[0][1]:.1f} m, lows {extremes(sw, -1)[0][1]:.1f} m")
print(f"mistake, high-water time as c in the sine: first high at {hm(extremes(wave(a, b, t1, d), 1)[0][0])}")
print(f"mistake, shift read before factoring, {b * c:.4f} h: first high at {hm(extremes(wave(a, b, b * c, d), 1)[0][0])}")
print(f"mistake, period where b goes: repeats every {2 * math.pi / P:.2f} h, {len(extremes(wave(a, P, c, d), 1))} highs a day")
X, Y = lambda t: 40 + 12.5 * t, lambda h: 200 - 40 * h   # figure: 1 h = 12.5 units, 1 m = 40, datum at y = 200
pt = lambda t, h: f"({X(t):.2f},{Y(h):.1f})"
print(f"figure, key (1 h = 12.5, 1 m = 40, datum at y = 200): highs {pt(t1, hi)} {pt(t3, hi)}, lows {pt(table[1][0], lo)} {pt(table[3][0], lo)}, c {pt(c, d)}")
tenths = sorted({5 * k for k in range(49)} | {round(10 * (c + k * P / 4)) for k in range(8)})
print("figure, curve: " + " ".join(f"{X(n / 10):.2f},{Y(y(n / 10)):.1f}" for n in tenths))
got = sorted(highs + lows)
assert len(got) == 4 and all(round(t * 60) == round(u * 60) and abs(v - w) < 1e-9 for (t, v), (u, w) in zip(got, table))
assert abs(ups[0] - c) < 1e-9 and abs(downs[0] - ups[0] - P / 2) < 1e-9   # starts at c; rises and falls alike
assert abs(rep - P) < 0.005                                    # the shortest repeat is the table's period
assert gap < 1e-12                                             # four formulas, one tide
print("ALL CHECKS PASS")
