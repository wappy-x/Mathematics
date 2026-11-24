# Complex measures and total variation -- the check behind the card.
# Standard library only; complex numbers are Python's built-in type.
# The runner: x is km run on a circular path of radius 1 km, so the heading
# at x is e^(ix).  nu(E) = integral over E of e^(ix) dx is the net
# displacement (east + i north) over the stretches E; |nu|(E) is the km run.
# Road 1: closed forms from the antiderivative e^(ix) / i.
# Road 2: midpoint sums for nu, |nu|, the real and imaginary parts, integrals.
# Road 3: total variation as a supremum: cut into n equal stretches and add
#         |nu(piece)| (inscribed polygons); all 203 cuts of six stretches;
#         |nu(E)| <= length(E) on all 4095 non-empty unions of twelve stretches.
# Polar form: h = nu(I) / |nu|(I) on short stretches I, against e^(ix).
# The code checks this example; the proofs cover every complex measure.
import math

TAU = 2 * math.pi
snap = lambda x: 0.0 if abs(x) < 5e-10 else x
r4 = lambda x: f"{snap(x):.4f}"
r6 = lambda x: f"{snap(x):.6f}"
def c4(z):
    re, im = snap(z.real), snap(z.imag)
    return f"{re:.4f} {'-' if im < 0 else '+'} {abs(im):.4f}i"
expi = lambda x: complex(math.cos(x), math.sin(x))
nu = lambda a, b: (expi(b) - expi(a)) / 1j                # road 1
def midpoint(g, a, b, n=200000):                         # road 2
    h = (b - a) / n
    return h * sum(g(a + (k + 0.5) * h) for k in range(n))

# the lap and the half lap
lap, lap_m = nu(0, TAU), midpoint(expi, 0, TAU)
run_m = midpoint(lambda x: abs(expi(x)), 0, TAU)
half, half_m = nu(0, math.pi), midpoint(expi, 0, math.pi)
assert abs(lap) < 1e-12 and abs(lap_m) < 1e-9 and abs(run_m - TAU) < 1e-9
assert abs(half - 2j) < 1e-12 and abs(half_m - 2j) < 1e-9
print(f"lap, nu([0, 2 pi]) closed form: {c4(lap)} | midpoint: {c4(lap_m)}")
print(f"lap, |nu|([0, 2 pi]) = km run: {r4(TAU)} | midpoint of |e^(ix)|: {r4(run_m)}")
print(f"half lap, nu([0, pi]) closed form: {c4(half)} | midpoint: {c4(half_m)}")
print(f"half lap, |nu([0, pi])| = {r4(abs(half))} km apart | |nu|([0, pi]) = {r4(math.pi)} km run")

# road 3: the supremum over cuts, approached by inscribed polygons
def cut(a, b, n):
    return sum(abs(nu(a + k * (b - a) / n, a + (k + 1) * (b - a) / n)) for k in range(n))
for n in (1, 2, 4, 6, 12, 96, 1000):
    s, poly = cut(0, TAU, n), 2 * n * math.sin(math.pi / n)
    assert abs(s - poly) < 1e-9 and s <= TAU + 1e-12
    print(f"cut lap into n = {n} stretches: sum |nu(piece)| = {r6(s)}")
for n in (1, 2, 1000):
    print(f"cut half lap into n = {n}: {r6(cut(0, math.pi, n))}")
assert abs(cut(0, math.pi, 1000) - math.pi) < 1e-5
assert TAU - cut(0, TAU, 1000) < 2e-5

def partitions(items):                         # every way to cut a list into blocks
    if not items:
        yield []
        return
    first, rest = items[0], items[1:]
    for part in partitions(rest):
        for k in range(len(part)):
            yield part[:k] + [[first] + part[k]] + part[k + 1:]
        yield [[first]] + part
six = [nu(k * TAU / 6, (k + 1) * TAU / 6) for k in range(6)]
parts = list(partitions(list(range(6))))
sums = [sum(abs(sum(six[i] for i in blk)) for blk in pt) for pt in parts]
best = max(sums)
assert len(parts) == 203 and abs(best - 6) < 1e-12 and sums.count(best) == 1
print(f"all {len(parts)} cuts of six 60-degree stretches: best {r4(best)}, from the finest cut only")

# real and imaginary parts: two signed measures, cos x dx and sin x dx
tv_r = midpoint(lambda x: abs(math.cos(x)), 0, TAU)
tv_i = midpoint(lambda x: abs(math.sin(x)), 0, TAU)
assert abs(tv_r - 4) < 1e-8 and abs(tv_i - 4) < 1e-8
assert max(tv_r, tv_i) <= TAU <= tv_r + tv_i
print(f"parts, |nu_r|([0, 2 pi]) = integral |cos x|: {r4(tv_r)} | |nu_i| = integral |sin x|: {r4(tv_i)}")
print(f"parts, max {r4(max(tv_r, tv_i))} <= |nu| {r4(TAU)} <= sum {r4(tv_r + tv_i)}"
      f" | square root of the sum of squares {r4(math.hypot(tv_r, tv_i))}")

# domination: length dominates nu on every union of twelve 30-degree stretches
twelve = [nu(k * TAU / 12, (k + 1) * TAU / 12) for k in range(12)]
ratios = []
for m in range(1, 4096):
    z = sum(twelve[k] for k in range(12) if m >> k & 1)
    ratios.append(abs(z) / (bin(m).count("1") * TAU / 12))
assert max(ratios) <= 1 and abs(max(ratios) - 2 * math.sin(math.pi / 12) / (math.pi / 6)) < 1e-12
print(f"dominate, |nu(E)| <= length(E) on all 4095 non-empty unions of twelve stretches; largest ratio {r6(max(ratios))}")
short = abs(nu(0, 0.1))
assert short > 0.99 * 0.1
print(f"dominate, 0.99 x length fails on [0, 0.1]: |nu| = {r6(short)} > {r6(0.99 * 0.1)}")

# polar form: h = nu(I) / |nu|(I) on I = [x - 0.0005, x + 0.0005]
for x in (0.0, 1.0, math.pi / 2, math.pi):
    h = nu(x - 0.0005, x + 0.0005) / 0.001
    assert abs(h - expi(x)) < 1e-7 and abs(abs(h) - 1) < 1e-7
    print(f"polar, x = {r4(x)}: h = {c4(h)}, |h| = {r6(abs(h))}, e^(ix) = {c4(expi(x))}")

# integrals against nu: integral f dnu = integral f(x) e^(ix) dx
for name, f, closed, bound in (("e^(-ix)", lambda x: expi(-x), TAU, TAU),
                               ("cos x", math.cos, math.pi, 4.0),
                               ("x", lambda x: x, -TAU * 1j, TAU * math.pi)):
    val = midpoint(lambda x: f(x) * expi(x), 0, TAU)
    rhs = midpoint(lambda x: abs(f(x)), 0, TAU)
    assert abs(val - closed) < 1e-8 and abs(rhs - bound) < 1e-8 and abs(val) <= rhs + 1e-9
    print(f"integral, f = {name}: integral f dnu = {c4(val)}, size {r4(abs(val))} <= integral |f| d|nu| = {r4(rhs)}")

# what breaks
print(f"breaks, |nu([0, 2 pi])| read as |nu|: {r4(abs(lap))}")
print(f"breaks, |nu_r| + |nu_i| read as |nu|: {r4(tv_r + tv_i)}")
print(f"breaks, the hexagon cut read as |nu|: {r4(cut(0, TAU, 6))}")
grow = [midpoint(lambda x: abs(expi(x)), 0, TAU * k, 20000) for k in (1, 10, 100)]
assert abs(grow[2] - 100 * TAU) < 1e-6
print("breaks, whole line: |nu|([0, 2 pi k]) for k = 1, 10, 100:", " ".join(r4(g) for g in grow))
print("breaks, whole line: nu([0, t]) for t = 1, 2, 3:", " ; ".join(c4(nu(0, t)) for t in (1, 2, 3)))

# try changing
tq = nu(0, 1.5 * math.pi)
print(f"try, three-quarter lap: nu([0, 3 pi/2]) = {c4(tq)}, size {r4(abs(tq))} | |nu| = {r4(1.5 * math.pi)}")
print(f"try, cut lap into n = 3 stretches: {r6(cut(0, TAU, 3))}")
vs = midpoint(lambda x: math.sin(x) * expi(x), 0, TAU)
assert abs(vs - math.pi * 1j) < 1e-8
print(f"try, f = sin x: integral f dnu = {c4(vs)}, size {r4(abs(vs))} <= {r4(tv_i)}")
print(f"try, 0.9999 x length: on [0, 0.1] {abs(nu(0, 0.1)):.8f} vs {0.9999 * 0.1:.8f};"
      f" on [0, 0.01] {abs(nu(0, 0.01)):.8f} vs {0.9999 * 0.01:.8f}")

# chart: distance apart against km run along the lap
ts = [k * math.pi / 4 for k in range(9)]
print("chart, km run t:", " ".join(f"{t:.2f}" for t in ts))
print("chart, |nu([0, t])| km apart:", " ".join(f"{abs(nu(0, t)):.2f}" for t in ts))
print("ALL CHECKS PASS")
