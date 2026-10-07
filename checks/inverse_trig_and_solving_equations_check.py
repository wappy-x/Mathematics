# Inverse trig and solving equations: the check behind the card.  Standard library
# only.  The tide h(t) = 1.5 + 1.5 sin(2 pi (t - 1) / 12.4) metres, t in hours after
# midnight.  When is the water above 2 m?  Road 1: the principal arcsin, its mirror
# and whole turns.  Road 1b: arccos, counted from high water.  Road 2 inverts
# nothing: it scans the day minute by minute and bisects each crossing.
from math import sin, asin, acos, pi, sqrt
MID, AMP, P, C, LEVEL = 1.5, 1.5, 12.4, 1.0, 2.0
h = lambda t: MID + AMP * sin(2 * pi * (t - C) / P)     # the gauge, in m, at t hours
to_time = lambda theta: C + P * theta / (2 * pi)        # undo theta = 2 pi (t - C) / P
hhmm = lambda t: f"{round(t * 60) // 60:02d}:{round(t * 60) % 60:02d}"
six = lambda xs: " ".join(f"{x:.6f}" for x in xs)
deg = lambda a: a * 180 / pi
u = (LEVEL - MID) / AMP
alpha, beta, high = asin(u), acos(u), C + P / 4         # high water: a quarter-tide on
rising = [to_time(alpha + 2 * pi * k) for k in range(-1, 3)]
falling = [to_time(pi - alpha + 2 * pi * k) for k in range(-1, 3)]
road1 = sorted(t for t in rising + falling if 0 <= t < 24)
half = P * beta / (2 * pi)                              # arccos: high water, plus or minus
road1b = sorted(t for k in range(-1, 3) for t in (high + P * k - half, high + P * k + half)
                if 0 <= t < 24)
road2 = []
for m in range(24 * 60):
    a, b = m / 60, (m + 1) / 60
    if (h(a) - LEVEL) * (h(b) - LEVEL) < 0:
        for _ in range(60):
            mid = (a + b) / 2
            a, b = (a, mid) if (h(a) - LEVEL) * (h(mid) - LEVEL) <= 0 else (mid, b)
        road2.append((a + b) / 2)
counted = sum(1 for m in range(24 * 60) if h((m + 0.5) / 60) > LEVEL)
window = P * (pi - 2 * alpha) / (2 * pi)
curve = " ".join(f"{36 + 6 * i},{200 - 50 * h(i / 2):.1f}" for i in range(49))
cx = sqrt(1 - u * u)
print(f"tide: low {MID - AMP:.1f} m, high {MID + AMP:.1f} m, period {P:.1f} h, rising through {MID:.1f} m at {hhmm(C)}; high water {hhmm(high)} and {hhmm(high + P)}")
print(f"u = ({LEVEL:.1f} - {MID:.1f}) / {AMP:.1f} = {u:.6f}")
print(f"road 1: arcsin(u) = {alpha:.6f} rad = {deg(alpha):.2f} deg; mirror pi - arcsin(u) = {pi - alpha:.6f} rad = {deg(pi - alpha):.2f} deg")
print(f"rising crossings, k = -1, 0, 1, 2 (h): {six(rising)}")
print(f"falling crossings, k = -1, 0, 1, 2 (h): {six(falling)}")
print(f"road 1, kept in [0, 24): {six(road1)}; heights there {six(h(t) for t in road1)}")
print(f"road 1b: arccos(u) = {beta:.6f} rad = {deg(beta):.2f} deg; high water +/- {half:.6f} h ({hhmm(half)}): {six(road1b)}")
print(f"road 2, minute scan and bisection: {six(road2)}")
print(f"above 2 m: {hhmm(road1[0])} to {hhmm(road1[1])} and {hhmm(road1[2])} to {hhmm(road1[3])}")
print(f"each window {window:.6f} h ({hhmm(window)}), {window / P:.6f} of a tide; minutes above 2 m: counted {counted}, formula {2 * window * 60:.2f}")
print(f"arcsin(sin({pi - alpha:.6f})) = {asin(sin(pi - alpha)):.6f}: the {hhmm(to_time(pi - alpha))} crossing comes back as {hhmm(to_time(asin(sin(pi - alpha))))}")
print(f"mistake 1, button only: {hhmm(rising[1])} and nothing else")
print(f"mistake 2, no whole turns: {hhmm(rising[1])} and {hhmm(falling[1])}; {hhmm(road1[2])} to {hhmm(road1[3])} lost")
print(f"mistake 3, midline skipped: {LEVEL:.1f} / {AMP:.1f} = {LEVEL / AMP:.6f}, {'outside [-1, 1]: no angle' if abs(LEVEL / AMP) > 1 else 'inside [-1, 1]'}")
print(f"mistake 4, degrees fed in as radians: first crossing at {to_time(deg(alpha)):.2f} h")
print(f"figure, tide, origin 36,200, 1 h = 12 units, 1 m = 50 units, half-hourly: {curve}")
print(f"figure, crossings x = {' '.join(f'{36 + 12 * t:.1f}' for t in road1)} on the 2 m line y = {200 - 50 * LEVEL:.1f}")
print(f"figure, circle centre 120,125 radius 90, line y = {125 - 90 * u:.1f}: points {120 + 90 * cx:.1f},{125 - 90 * u:.1f} and {120 - 90 * cx:.1f},{125 - 90 * u:.1f}; "
      f"arcs radius 28 from {120 + 28},125 and {120 - 28},125 to {120 + 28 * cx:.1f},{125 - 28 * u:.1f} and {120 - 28 * cx:.1f},{125 - 28 * u:.1f}")
assert len(road2) == len(road1) and all(abs(x - y) < 1e-9 for x, y in zip(road1, road2))
assert len(road1b) == len(road1) and all(abs(x - y) < 1e-9 for x, y in zip(road1, road1b))
assert all(abs(h(t) - LEVEL) < 1e-12 for t in road1)          # each time, plugged back in
assert abs(counted - 2 * window * 60) <= 2                      # slices against the formula
print("ALL CHECKS PASS")
