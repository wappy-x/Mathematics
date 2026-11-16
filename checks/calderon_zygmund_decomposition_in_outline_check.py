# Calderon-Zygmund decomposition of a 32-day rainfall record (illustrative numbers).
# Road 1: start from the whole record and halve each box, stopping at the first
#         box whose average rain is above the level ALPHA.
# Road 2: list every dyadic box with average above ALPHA, keep the largest ones.
# Road 3: the dyadic maximal function, day by day; its level set must be the same days.
# Rain is whole mm per day, so every average is an exact fraction with a power-of-two
# denominator; dec() prints it exactly. Logs appear only in the far-field table.
from math import log, pi

RAIN = [0, 2, 0, 14, 4, 0, 1, 0, 3, 0, 0, 25, 30, 2, 0, 0,
        0, 0, 6, 8, 9, 7, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0]   # mm on each day
ALPHA = 10                                                  # level, mm per day

def dec(n, d):  # exact decimal of n/d, d a power of two
    s = "-" if n < 0 else ""
    q, r = divmod(abs(n), d)
    out = s + str(q) + ("." if r else "")
    while r:
        r *= 10
        out += str(r // d)
        r %= d
    return out

def show(bx, shift=0):
    return " ".join(f"[{a - shift},{a - shift + n})" for a, n in bx)

def tot(rain, a, n):
    return sum(rain[a:a + n])

def halve(rain, alpha, a, n, out, seen):  # road 1, the stopping time
    seen[n] = seen.get(n, 0) + 1
    if tot(rain, a, n) > alpha * n:
        out.append((a, n))
    elif n > 1:  # a one-day box is constant inside: halving it never stops
        halve(rain, alpha, a, n // 2, out, seen)
        halve(rain, alpha, a + n // 2, n // 2, out, seen)
    return out

def largest(rain, alpha):  # road 2, bottom up
    hot, n = [], 1
    while n <= len(rain):
        hot += [(a, n) for a in range(0, len(rain), n) if tot(rain, a, n) > alpha * n]
        n *= 2
    inside = lambda b, c: c != b and c[0] <= b[0] and b[0] + b[1] <= c[0] + c[1]
    return sorted(b for b in hot if not any(inside(b, c) for c in hot))

L, F1 = len(RAIN), sum(RAIN)
print(f"record: {L} days, total {F1} mm, level ALPHA = {ALPHA} mm/day, 2 ALPHA = {2 * ALPHA}")
print(f"start box [0,{L}): average {dec(F1, L)} mm/day, not above {ALPHA}")
seen = {}
boxes = halve(RAIN, ALPHA, 0, L, [], seen)
for n in sorted(seen, reverse=True):
    print(f"  boxes of length {n:>2} looked at: {seen[n]:>2}, stopped: {sum(1 for b in boxes if b[1] == n)}")
for a, n in boxes:
    t = tot(RAIN, a, n)
    path = [(a - a % m, m) for m in (32, 16, 8, 4, 2) if m > n]
    print(f"stopped [{a},{a + n}): length {n}, {t} mm, average {dec(t, n)}; above it: "
          + ", ".join(f"[{s},{s + m}) {tot(RAIN, s, m)}/{m} = {dec(tot(RAIN, s, m), m)}" for s, m in path))
assert boxes == [(3, 1), (10, 2), (12, 2), (28, 4)], "the hand-worked halving"
assert boxes == largest(RAIN, ALPHA), "road 2: largest hot boxes"
for a, n in boxes:
    assert ALPHA * n < tot(RAIN, a, n) <= 2 * ALPHA * n, "average between ALPHA and 2 ALPHA"
bad_days = sorted(d for a, n in boxes for d in range(a, a + n))
md_hot = [d for d in range(L) if any(tot(RAIN, d - d % n, n) > ALPHA * n for n in (1, 2, 4, 8, 16, 32))]
assert md_hot == bad_days, "road 3: dyadic maximal function above ALPHA on exactly the boxes"
print(f"road 2, largest hot boxes: {show(largest(RAIN, ALPHA))}")
print(f"road 3, days with dyadic maximal function above {ALPHA}: {md_hot}")
inbox = sum(tot(RAIN, a, n) for a, n in boxes)
print(f"length of boxes {len(bad_days)} days < rain in boxes {inbox} mm / ALPHA = {dec(inbox, ALPHA)} <= total / ALPHA = {dec(F1, ALPHA)}")
assert len(bad_days) * ALPHA < inbox <= F1, "length bound"
assert max(RAIN[d] for d in range(L) if d not in bad_days) <= ALPHA, "outside the boxes, rain <= ALPHA"

g32 = [32 * r for r in RAIN]   # good part times 32, so it stays a whole number
for a, n in boxes:
    for d in range(a, a + n):
        g32[d] = 32 * tot(RAIN, a, n) // n
b32 = [32 * r - g for r, g in zip(RAIN, g32)]
for a, n in boxes:
    print(f"  bad part on [{a},{a + n}): {" ".join(dec(x, 32) for x in b32[a:a + n])}, sum {dec(sum(b32[a:a + n]), 32)}, size {dec(sum(abs(x) for x in b32[a:a + n]), 32)}")
    assert sum(b32[a:a + n]) == 0, "bad part nets to zero on each box"
e_g, e_f = sum(x * x for x in g32), 1024 * sum(r * r for r in RAIN)
print(f"good part: largest {dec(max(g32), 32)} mm/day, total {dec(sum(g32), 32)} mm, energy {dec(e_g, 1024)}")
print(f"rain energy {dec(e_f, 1024)}; bound on good energy 2 ALPHA x total = {2 * ALPHA * F1}")
print(f"bad part: total size {dec(sum(abs(x) for x in b32), 32)} mm <= 2 x rain in boxes = {2 * inbox}")
assert max(g32) <= 64 * ALPHA and sum(g32) == 32 * F1 and e_g <= 1024 * 2 * ALPHA * F1 < e_f

def pull(vals, a, x):  # Hilbert transform at x of a day-by-day step function starting on day a
    return sum(v * (log(abs(x - d)) - log(abs(x - d - 1))) for d, v in zip(range(a, a + len(vals)), vals)) / pi
cut = [max(r - ALPHA, 0) for r in RAIN[28:32]]   # the truncation remainder on [28,32)
print("far field of [28,32): distance, bad part, cut-at-level remainder, ratio")
ratios = []
for dist in (8, 16, 32, 64):
    hb, hc = pull([x / 32 for x in b32[28:32]], 28, 30 - dist), pull(cut, 28, 30 - dist)
    ratios.append(abs(hb / hc))
    print(f"  {dist:>3} days  {hb:>10.6f}  {hc:>10.6f}  {ratios[-1]:.6f}")
assert all(r2 < 0.65 * r1 for r1, r2 in zip(ratios, ratios[1:])), "bad part fades faster"
m1 = sum(x / 32 * (d + 0.5 - 30) for d, x in zip(range(28, 32), b32[28:32]))   # first moment, -24
print(f"at 64 days, bad part x distance^2 = {hb * 64 ** 2:.6f}; first moment {m1:.1f} mm x days, / pi = {m1 / pi:.6f}")
print(f"at 64 days, remainder x distance = {hc * 64:.6f}; -38 / pi = {-38 / pi:.6f}")
assert abs(hb * 64 ** 2 / (m1 / pi) - 1) < 0.05 and abs(hc * 64 / (-38 / pi) - 1) < 0.05, "far-field laws"

trunc = [max(r - ALPHA, 0) for r in RAIN]
print(f"wrong: cut at the level, remainder total {sum(trunc)} mm, on days {[d for d in range(L) if trunc[d]]}")
print(f"wrong: start at single days, largest box average {max(RAIN)} > 2 ALPHA = {2 * ALPHA}")
print(f"wrong: good part <= ALPHA, but it reaches {dec(max(g32), 32)}")
print(f"fails: 12 mm/day forever, average over 2^n days for n = 5, 10, 20: {", ".join(dec(12 * 2 ** n, 2 ** n) for n in (5, 10, 20))}")
shift = [0] + RAIN + [0] * 31
sb = halve(shift, ALPHA, 0, 64, [], {})
print(f"grid moved one day: boxes {show(sb, 1)}, length {sum(n for _, n in sb)} days")
for label, rain, alpha in (("try: ALPHA = 5", RAIN, 5), ("try: ALPHA = 20", RAIN, 20),
                           ("try: day 29 = 96 mm", RAIN[:29] + [96] + RAIN[30:], ALPHA)):
    bx = halve(rain, alpha, 0, L, [], {})
    assert bx == largest(rain, alpha)
    print(f"{label}: boxes {show(bx)}, length {sum(n for _, n in bx)} days")
print("chart, rain      " + " ".join(str(r) for r in RAIN))
print("chart, good part " + " ".join(dec(g, 32) for g in g32))
print("figure, x = 40 + 18 x day px, bar height 3 px per mm from y = 190, ALPHA line y = 160, 2 ALPHA line y = 130")
print("figure, stopped boxes px " + ", ".join(f"{40 + 18 * a}-{40 + 18 * (a + n)}" for a, n in boxes))
print("ALL CHECKS PASS")
