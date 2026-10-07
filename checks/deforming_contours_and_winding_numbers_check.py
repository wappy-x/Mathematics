# Deforming a loop and winding numbers -- the check behind the card.  Standard
# library only.  Metres.  An oval roundabout lane, 12 by 8, round an island at 0;
# a double roundabout with islands at 5 and -5, driven as a figure-eight.
# Road one: a trapezoid sum of f(z) dz along the path.  Road two: add up, step
# by step with atan2, how far the arrow from the island to the car turns.
import math
TAU, N = 2 * math.pi, 100000
def clean(x): return 0.0 if abs(x) < 5e-7 else x
def fmt(z): return f"{clean(z.real):.6f} {'-' if clean(z.imag) < 0 else '+'} {abs(clean(z.imag)):.6f}i"
def path(curve, t0, t1, n): return [curve(t0 + (t1 - t0) * k / n) for k in range(n + 1)]
def integral(f, zs): return sum((f(u) + f(v)) / 2 * (v - u) for u, v in zip(zs, zs[1:]))
def turns(zs, a):
    steps = ((w - a) / (v - a) for v, w in zip(zs, zs[1:]))
    return sum(math.atan2(s.imag, s.real) for s in steps) / TAU
def pole(a): return lambda z: 1 / (z - a)
def oval(t, shift=0): return complex(12 * math.cos(t) + shift, 8 * math.sin(t))
def eight(t): return complex(10 * math.cos(t), 5 * math.sin(2 * t))
def ring(c, r): return lambda t: c + complex(r * math.cos(t), r * math.sin(t))
def f(z): return (4 * z + 10) / (z * z - 25)          # = 3/(z - 5) + 1/(z + 5)
def fig(z, sc, ox, oy): return f"({ox + sc * z.real:.0f}, {oy - sc * z.imag:.0f})"
print(f"figure, lane: scale 9 px per m, island {fig(0j, 9, 150, 120)}, lane east {fig(oval(0), 9, 150, 120)}, "
      f"lane north {fig(oval(TAU / 4), 9, 150, 120)}, bus stop {fig(15 + 0j, 9, 150, 120)}")
print(f"figure, eight: scale 14 px per m, islands {fig(5 + 0j, 14, 180, 120)} and {fig(-5 + 0j, 14, 180, 120)}, "
      f"ends {fig(eight(0), 14, 180, 120)} and {fig(eight(math.pi), 14, 180, 120)}, lobe top {fig(eight(math.pi / 4), 14, 180, 120)}")
laps = [("one lap", path(oval, 0, TAU, N), 1), ("two laps", path(oval, 0, 2 * TAU, 2 * N), 2),
        ("wrong way", path(oval, TAU, 0, N), -1)]
for name, zs, hand in laps:
    n1, n2 = integral(pole(0), zs) / (TAU * 1j), turns(zs, 0)
    print(f"{name} round island 0: integral / 2 pi i = {fmt(n1)}; turns counted = {clean(n2):.6f}")
    assert abs(n1 - n2) < 1e-6 and round(n2) == hand                   # two roads agree, and match the hand count
lane, bus = laps[0][1], 15 + 0j
print(f"bus stop at 15, outside the lane: integral / 2 pi i = {fmt(integral(pole(bus), lane) / (TAU * 1j))}; turns counted = {clean(turns(lane, bus)):.6f}")
small = [integral(pole(0), path(ring(0, r), 0, TAU, N)) for r in (1, 0.1)]
big = integral(pole(0), lane)
print(f"integral of dz/z: oval lane {fmt(big)}; circle radius 1 {fmt(small[0])}; radius 0.1 {fmt(small[1])}; 2 pi = {TAU:.6f}")
assert abs(big - small[0]) < 1e-5 and abs(small[0] - small[1]) < 1e-5  # deformation: three loops, one value
e8 = path(eight, 0, TAU, N)
w5, wm5 = turns(e8, 5), turns(e8, -5)
print(f"figure-eight winding about 5: integral / 2 pi i = {fmt(integral(pole(5), e8) / (TAU * 1j))}; turns counted = {w5:.6f}")
print(f"figure-eight winding about -5: integral / 2 pi i = {fmt(integral(pole(-5), e8) / (TAU * 1j))}; turns counted = {wm5:.6f}")
h5, hm5 = (integral(f, path(ring(c, 1), 0, TAU, N)) for c in (5, -5))
holes = round(w5) * h5 + round(wm5) * hm5
print(f"small circles round the holes of f: at 5 {fmt(h5)}; at -5 {fmt(hm5)}; winding-weighted sum {fmt(holes)}")
errs = [abs(integral(f, path(eight, 0, TAU, n)) - holes) for n in (100, 1000, 10000)]
print(f"cancellation, 1/(z - 5) + 1/(z + 5) round the figure-eight: {fmt(integral(lambda z: 1 / (z - 5) + 1 / (z + 5), e8))}")
print(f"f round the figure-eight directly, {N} steps: {fmt(integral(f, path(eight, 0, TAU, N)))}; error at 100, 1000, 10000 steps: "
      + ", ".join(f"{e:.2e}" for e in errs))
assert (round(w5), round(wm5)) == (1, -1) and abs(holes - 2 * TAU * 1j) < 1e-5 \
    and errs[2] < 1e-5 and errs[0] > errs[1] > errs[2]  # windings +1, -1; 4 pi i by hand; direct sum agrees, error shrinking
both = integral(f, lane)
print(f"f round the oval lane, both holes inside: {fmt(both)}; 2 pi i (3 + 1) = {fmt(TAU * 4j)}")
assert abs(both - (h5 + hm5)) < 1e-5 and abs(both - TAU * 4j) < 1e-5   # big loop = both circles = 2 pi i (3 + 1)
print(f"mistake 1, lane slid 20 m east past the island: integral of dz/z = {fmt(integral(pole(0), path(lambda t: oval(t, 20), 0, TAU, N)))}, not {fmt(big)}")
print(f"mistake 2, figure-eight with direction ignored: {fmt(h5 + hm5)}, not {fmt(holes)}")
print(f"mistake 3, two laps counted as 'inside, so once': {fmt(TAU * 1j)}, not {fmt(integral(pole(0), laps[1][1]))}")
print("ALL CHECKS PASS")
