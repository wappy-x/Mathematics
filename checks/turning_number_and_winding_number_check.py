# Turning and winding numbers -- the check behind the card.  Only math is
# imported.  A 400 m running track (straights 84.39 m, bends of radius 36.80 m
# on the running line) is lapped anticlockwise.  Its turns are counted two
# ways, the heading (turning number) and the arrow from a point (winding
# number), each by an angle sum and by a signed crossing count.
from math import atan2, cos, sin, pi, hypot

ELL, RHO, N = 84.39, 36.80, 4000
BEND = pi * RHO                         # length of one bend
L = 2 * ELL + 2 * BEND                  # length of the lap on the running line
RC = L / (2 * pi)                       # radius of a circle of the same length

def heading(s):                         # exact heading, radians from due east, by pieces
    s %= L
    if s < ELL: return 0.0
    if s < ELL + BEND: return (s - ELL) / RHO
    if s < 2 * ELL + BEND: return pi
    return pi + (s - 2 * ELL - BEND) / RHO

def track(s):                           # position, s metres from the home straight's start
    s %= L
    if s < ELL: return (-ELL / 2 + s, -RHO)
    if s < ELL + BEND:
        t = (s - ELL) / RHO
        return (ELL / 2 + RHO * sin(t), -RHO * cos(t))
    if s < 2 * ELL + BEND: return (ELL / 2 - (s - ELL - BEND), RHO)
    t = (s - 2 * ELL - BEND) / RHO
    return (-ELL / 2 - RHO * sin(t), RHO * cos(t))

def circle(s): return (RC * sin(s / RC), -RC * cos(s / RC))

def angle_sum(pts, a):                  # road 2: add up each step's turn of the arrow from a
    tot = 0.0
    for k in range(len(pts)):
        (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
        x1, y1, x2, y2 = x1 - a[0], y1 - a[1], x2 - a[0], y2 - a[1]
        tot += atan2(x1 * y2 - y1 * x2, x1 * x2 + y1 * y2)
    return tot

def crossings(pts, a):                  # road 3: signed crossings of the ray due east of a
    n = 0
    for k in range(len(pts)):
        (x1, y1), (x2, y2) = pts[k], pts[(k + 1) % len(pts)]
        y1, y2 = y1 - a[1], y2 - a[1]
        if (y1 < 0) != (y2 < 0) and x1 + (x2 - x1) * y1 / (y1 - y2) > a[0]:
            n += 1 if y2 >= 0 else -1
    return n

def steps(pts):                         # the chord directions: a sampled velocity curve
    return [(pts[(k + 1) % len(pts)][0] - pts[k][0], pts[(k + 1) % len(pts)][1] - pts[k][1])
            for k in range(len(pts))]

def turns(pts):                         # turning number two ways: the velocity's winding round 0
    return angle_sum(steps(pts), (0.0, 0.0)) / (2 * pi), crossings(steps(pts), (0.0, 0.0))

def sweep(pts):                         # an open path's turn of the arrow from the origin
    return sum(atan2(x1 * y2 - y1 * x2, x1 * x2 + y1 * y2) for (x1, y1), (x2, y2) in zip(pts, pts[1:]))

def f6(x): return f"{0.0 if abs(x) < 5e-7 else x:.6f}"
def d2(x): return f"{x * 180 / pi:.2f}"

lap = [track(L * k / N) for k in range(N)]
print(f"track: straights {ELL:.2f} m, bends of radius {RHO:.2f} m, lap {L:.2f} m")
print(f"bend {BEND:.2f} m long, curvature {1 / RHO:.6f} 1/m, heading turned {f6(BEND / RHO)} rad = {d2(BEND / RHO)} deg")
pieces = [k * ds for k, ds in [(0.0, ELL), (1 / RHO, BEND), (0.0, ELL), (1 / RHO, BEND)]]
print("curvature x length, by pieces: " + " + ".join(d2(p) for p in pieces) + f" = {d2(sum(pieces))} deg")
c0 = atan2(RHO, ELL / 2)                # angle of a straight's end seen from the centre
sweeps = [pi - 2 * c0, 2 * c0, pi - 2 * c0, 2 * c0]
print(f"bearing from the centre: a straight's end {c0 * 180 / pi:.3f} deg off level (half-straight {ELL / 2:.3f} m); start {d2(pi + c0)} deg")
print("sight-line sweeps: " + " + ".join(d2(p) for p in sweeps) + f" = {d2(sum(sweeps))} deg")
ta, tc = turns(lap)
print(f"sampled lap, {N} points: heading angle sum {f6(2 * pi * ta)} rad = {f6(ta)} turns; velocity crossings {tc}")
CENTRE, COACH = (0.0, 0.0), (0.0, -50.0)
for name, a in [("centre (0, 0)", CENTRE), ("coach (0, -50)", COACH)]:
    print(f"winding round the {name}: angle sum {f6(angle_sum(lap, a) / (2 * pi))} turns; ray crossings {crossings(lap, a)}")
chart_s = [L * k / 10 for k in range(11)]
bear, acc, prev = [], 0.0, atan2(*track(0)[::-1])
for s in chart_s:
    b = atan2(*track(s)[::-1])
    acc += (b - prev + pi) % (2 * pi) - pi
    prev = b
    bear.append(acc)
print("chart s (m): " + ", ".join(f"{s:.0f}" for s in chart_s))
print("chart track heading turned (deg): " + ", ".join(f"{h * 180 / pi:.1f}" for h in [heading(s) for s in chart_s[:-1]] + [2 * pi]))
print("chart circle heading turned (deg): " + ", ".join(f"{s / RC * 180 / pi:.1f}" for s in chart_s))
print("chart bearing from centre turned (deg): " + ", ".join(f"{b * 180 / pi:.1f}" for b in bear))
print(f"deformation: track (u = 0) into a circle of radius {RC:.2f} m (u = 1), both start heading east, same s")
stages = []
for u in [0.0, 0.25, 0.5, 0.75, 1.0]:
    pts = [((1 - u) * track(s)[0] + u * circle(s)[0], (1 - u) * track(s)[1] + u * circle(s)[1])
           for s in [L * k / N for k in range(N)]]
    slow = min(hypot((1 - u) * cos(heading(s)) + u * cos(s / RC), (1 - u) * sin(heading(s)) + u * sin(s / RC))
               for s in [L * k / N for k in range(N)])
    t, c = turns(pts)
    wc, wk = angle_sum(pts, CENTRE) / (2 * pi), angle_sum(pts, COACH) / (2 * pi)
    stages.append((slow, round(t), c, round(wc), round(wk), crossings(pts, COACH)))
    print(f"  u = {u:.2f}: least speed {f6(slow)}, turning {f6(t)} (crossings {c}), winding round centre {round(wc)}, round coach {round(wk)} (crossings {crossings(pts, COACH)})")
eight = [(60 * sin(2 * pi * k / N), 30 * sin(4 * pi * k / N)) for k in range(N)]
e_t, e_c = turns(eight)
e_w = [round(angle_sum(eight, (x, 0.0)) / (2 * pi)) for x in (40.0, -40.0)]
print(f"figure-eight (60 sin t, 30 sin 2t) m: turning {f6(e_t)} (crossings {e_c}); winding round (40, 0) {e_w[0]}, round (-40, 0) {e_w[1]}")
def limacon(b, m):
    return [((b + 20 * cos(t)) * cos(t), (b + 20 * cos(t)) * sin(t)) for t in [2 * pi * k / m for k in range(m)]]
lim = {}
for b in [30.0, 20.0, 10.0]:
    slow = min(hypot(-20 * sin(t) * cos(t) - (b + 20 * cos(t)) * sin(t), -20 * sin(t) * sin(t) + (b + 20 * cos(t)) * cos(t))
               for t in [2 * pi * k / N for k in range(N)])
    if slow < 1e-9:
        print(f"limacon r = {b:.0f} + 20 cos t m: least speed {f6(slow)} at the cusp, so no tangent there and no turning number")
        lim[b] = (slow,)
        continue
    pts = limacon(b, N)
    t, c = turns(pts)
    w = [round(angle_sum(pts, (x, 0.0)) / (2 * pi)) for x in (5.0, 20.0, 40.0)]
    lim[b] = (slow, round(t), c, w)
    print(f"limacon r = {b:.0f} + 20 cos t m: least speed {f6(slow)}, turning {f6(t)} (crossings {c}); winding round (5, 0), (20, 0), (40, 0): {w}")
half = heading(L / 2) / (2 * pi)
absk = sum(abs(atan2(x1 * y2 - y1 * x2, x1 * x2 + y1 * y2)) for (x1, y1), (x2, y2) in zip(steps(eight), steps(eight)[1:] + steps(eight)[:1])) / (2 * pi)
COARSE = 5                              # sample points for mistake 3
coarse = turns(limacon(10.0, COARSE))
print(f"mistake 1, half a lap is no loop: heading turned {d2(2 * pi * half)} deg = {f6(half)} turns")
print(f"mistake 2, adding |kappa| on the figure-eight: {f6(absk)} turns, not 0")
print(f"mistake 3, limacon r = 10 + 20 cos t sampled at {COARSE} points: turning {f6(coarse[0])}, not 2")
assert abs(2 * pi * ta - sum(pieces)) < 1e-9 and tc == round(ta) == 1      # exact pieces vs samples
assert abs(sum(sweeps) - angle_sum(lap, CENTRE)) < 1e-9                       # by hand vs samples
assert all(abs(sweep([track(a + d * k / 100) for k in range(101)]) - w) < 1e-9 for a, d, w in [(0.0, ELL, sweeps[0]), (ELL, BEND, sweeps[1])])
assert crossings(lap, CENTRE) == 1 and crossings(lap, COACH) == 0
assert max(abs(hypot(*d) - L / N) for d in steps(lap)) < 1e-6                 # samples evenly spaced: no jumps
assert all(st[0] > 0.5 and st[1] == st[2] == 1 and st[3] == 1 for st in stages)
assert [st[4] for st in stages] == [st[5] for st in stages] and stages[0][4] == 0 and stages[-1][4] == 1
assert round(e_t) == e_c == 0 and e_w == [-1, 1]
assert lim[30.0][1] == lim[30.0][2] == 1 and lim[10.0][1] == lim[10.0][2] == 2 and len(lim[20.0]) == 1
assert all(abs(lim[b][0] - abs(b - 20)) < 1e-6 for b in lim)                # least speed = |b - 20|, at t = pi
print("ALL CHECKS PASS")
