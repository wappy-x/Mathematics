# Weyl's law -- the check behind the card.  Standard library only.
# A round rubber sheet of radius 1 m, clamped at the rim: its modes are -Laplacian
# eigenvalues lambda = j^2 (1/m^2), j a zero of a Bessel function J_m.  Count them below
# lambda = 1000 by two roads: Bessel's integral with bisection, and Miller's backward
# recurrence with sign changes.  Then the square-grid sandwich of Weyl's proof,
# the free rim, an L-shaped sheet with no formula, and what breaks.
import math
PI = math.pi
LAM = 1000.0
X = math.sqrt(LAM)

def J(m, x):                     # Bessel's integral, midpoint rule (exact to rounding here)
    n, total = 160, 0.0
    for i in range(n):
        t = PI * (i + 0.5) / n
        total += math.cos(m * t - x * math.sin(t))
    return total / n

def Jp(m, x):                    # derivative: J_m' = (J_(m-1) - J_(m+1)) / 2
    return -J(1, x) if m == 0 else 0.5 * (J(m - 1, x) - J(m + 1, x))

def zeros(f, m, top):            # scan in steps of 0.1, then bisect each sign change
    out, a = [], max(m, 0.5)
    fa = f(m, a)
    while a < top:
        b = min(a + 0.1, top)
        fb = f(m, b)
        if fa * fb < 0:
            lo, hi = a, b
            for _ in range(55):
                mid = 0.5 * (lo + hi)
                if fa * f(m, mid) <= 0: hi = mid
                else: lo = mid
            out.append(0.5 * (lo + hi))
        a, fa = b, fb
    return out

def count(f, extra):             # modes with multiplicity: m >= 1 counts twice (cos and sin)
    eig, m = [], 0
    while True:
        z = zeros(f, m, X)
        if not z: break
        eig += [x * x for x in z] * (1 if m == 0 else 2)
        m += 1
    return sorted(eig + extra), m - 1

def miller(x, top):              # J_0..J_top at x by backward recurrence, normalised
    start = max(int(x), top) + 60
    a, b, out = 0.0, 1e-30, [0.0] * (start + 1)
    for k in range(start, 0, -1):
        a, b = b, 2 * k / x * b - a
        out[k - 1] = b
        if abs(b) > 1e250: out = [v * 1e-250 for v in out]; a *= 1e-250; b *= 1e-250
    norm = out[0]
    for k in range(2, start + 1, 2): norm += 2 * out[k]
    return [v / norm for v in out[:top + 1]]

def nd(r): return sum(1 for p in range(1, int(r) + 2) for q in range(1, int(r) + 2) if p * p + q * q <= r * r)
def nn(r): return sum(1 for p in range(int(r) + 2) for q in range(int(r) + 2) if p * p + q * q <= r * r)
def rect(a, b, lam, lo): return sum(1 for p in range(lo, int(a * math.sqrt(lam) / PI) + 2) for q in range(lo, int(b * math.sqrt(lam) / PI) + 2) if PI * PI * (p * p / a / a + q * q / b / b) <= lam)
def weyl(area, edge, lam, sign): return area * lam / (4 * PI) + sign * edge * math.sqrt(lam) / (4 * PI)

print(f"clamped disc, radius 1 m, area {PI:.5f} m^2, rim 2 pi = {2 * PI:.5f} m; count lambda <= {LAM:.0f} 1/m^2 (k <= {X:.4f} 1/m)")
eig, mtop = count(J, [])
j01, j11, j21, j02 = zeros(J, 0, 3)[0], zeros(J, 1, 4)[0], zeros(J, 2, 6)[0], zeros(J, 0, 6)[1]
print(f"first zeros: j01 = {j01:.6f}, j11 = {j11:.6f}, j21 = {j21:.6f}, j02 = {j02:.6f}; lambda1 = {j01 ** 2:.4f} 1/m^2")
N1 = len(eig)
distinct = len(set(round(v, 9) for v in eig))
print(f"road 1, Bessel's integral: N(1000) = {N1} modes ({distinct} distinct notes), orders m = 0 to {mtop}")
xs = [0.05 * i for i in range(1, int(X / 0.05) + 1)] + [X]
vals = [miller(x, int(X)) for x in xs]   # every order with a zero below X (j_(m,1) > m)
N2 = sum((1 if m == 0 else 2) * sum(1 for i in range(len(xs) - 1) if vals[i][m] * vals[i + 1][m] < 0) for m in range(int(X) + 1))
print(f"road 2, Miller recurrence on a 0.05 grid: N(1000) = {N2} modes; J_5(20) by both roads: {J(5, 20):.10f} {miller(20, 5)[5]:.10f}")
gap = min(abs(v - LAM) for v in eig)
w1, w2 = weyl(PI, 2 * PI, LAM, 0), weyl(PI, 2 * PI, LAM, -1)
print(f"nearest eigenvalue to the limit is {gap:.3f} 1/m^2 away; Weyl area term {w1:.2f}, rim term {w1 - w2:.2f}, two terms {w2:.2f}; exact {N1}")
print(f"errors: area term {w1 - N1:+.2f}, two terms {w2 - N1:+.2f}; ratio N / area term = {N1 / w1:.4f}")
lams = list(range(100, 1001, 100))
stair = [sum(1 for v in eig if v <= l) for l in lams]
print("chart lambda:", lams)
print("chart exact N:", stair)
print("chart area term: [" + ", ".join(f"{weyl(PI, 0, l, 0):.1f}" for l in lams) + "]")
print("chart two terms: [" + ", ".join(f"{weyl(PI, 2 * PI, l, -1):.1f}" for l in lams) + "]")
c = math.sqrt(200 / 0.5)
print(f"sheet: tension 200 N/m, 0.5 kg/m^2, c = {c:.1f} m/s; first note {c * j01 / (2 * PI):.3f} Hz; limit {c * X / (2 * PI):.2f} Hz; modes per Hz there {2 * PI * PI * c * X / (2 * PI) / c ** 2:.3f}")
print(f"min-max sandwich of lambda1: inner square side sqrt2 {PI * PI:.4f} >= disc {j01 ** 2:.4f} >= covering square side 2 {PI * PI / 2:.4f}")
R = X / PI
print(f"unit square, l = sqrt(1000)/pi = {R:.4f}: N_D = {nd(R)}, N_N = {nn(R)}, area term pi l^2/4 = {PI * R * R / 4:.2f}, slack 2l+1 = {2 * R + 1:.2f}")
print(f"unit square with edge term: clamped {weyl(1, 4, LAM, -1):.2f} (exact {nd(R)}), free {weyl(1, 4, LAM, 1):.2f} (exact {nn(R)})")
def sandwich(s, lam):           # squares inside give a floor, squares meeting the disc a ceiling
    k, inn, out = round(1 / s), 0, 0
    for i in range(-k, k):
        for j in range(-k, k):
            x0, x1, y0, y1 = i * s, (i + 1) * s, j * s, (j + 1) * s
            far = max(x0 * x0, x1 * x1) + max(y0 * y0, y1 * y1)
            near = (0 if x0 <= 0 <= x1 else min(x0 * x0, x1 * x1)) + (0 if y0 <= 0 <= y1 else min(y0 * y0, y1 * y1))
            inn += far < 1
            out += near < 1
    r = s * math.sqrt(lam) / PI
    assert PI * r * r / 4 - 2 * r - 1 <= nd(r) <= PI * r * r / 4 <= nn(r) <= PI * r * r / 4 + 2 * r + 1   # lattice bounds
    return inn, out, inn * nd(r), out * nn(r)
fig = None
for s in (0.5, 0.25, 0.125):
    inn, out, lo, hi = sandwich(s, LAM)
    print(f"disc at lambda 1000, squares of side {s} m: {inn} inside, {out} meeting; {lo} <= N <= {hi}")
    assert lo <= N1 <= hi                                                       # the sandwich holds
    fig = (inn, out) if s == 0.25 else fig
print("squeeze: side s, lambda, 4 pi N_low/lambda, 4 pi N_high/lambda (target area pi = 3.14159)")
sq = []
for s, lam in ((0.2, 10 ** 4), (0.1, 10 ** 5), (0.05, 10 ** 6), (0.025, 10 ** 7)):
    inn, out, lo, hi = sandwich(s, lam)
    sq.append((4 * PI * lo / lam, 4 * PI * hi / lam))
    print(f"  {s:<5} {lam:<8}  {sq[-1][0]:.4f}  {sq[-1][1]:.4f}  (inner area {inn * s * s:.4f}, outer {out * s * s:.4f} m^2)")
assert all(sq[i][0] < sq[i + 1][0] < PI < sq[i + 1][1] < sq[i][1] for i in range(3))   # bracket closes on the area
eigN, _ = count(Jp, [0.0])
NN1 = sum(1 for v in eigN if v <= LAM)
w3 = weyl(PI, 2 * PI, LAM, +1)
print(f"free rim (Neumann, zeros of J_m'): N(1000) = {NN1}; Weyl with + rim term {w3:.2f}")
lsq = (3 * nd(R), 3 * nn(R))
lre = (rect(2, 1, LAM, 1) + nd(R), rect(2, 1, LAM, 0) + nn(R))
wl1, wl2 = weyl(3, 8, LAM, 0), weyl(3, 8, LAM, -1)
print(f"L-shaped sheet, three 1 m squares (area 3 m^2, edge 8 m): squares give {lsq[0]} <= N <= {lsq[1]}")
print(f"  2 m x 1 m rectangle plus a square give {lre[0]} <= N <= {lre[1]}; Weyl {wl1:.2f}, with edge term {wl2:.2f}")
print(f"  as notes: about {wl2:.0f} modes below {c * X / (2 * PI):.2f} Hz on a 3 m^2 L-shaped sheet")
strip = [rect(L, 1, LAM, 1) for L in (1, 10, 100)]
print(f"strip 1 m wide, Dirichlet, lambda <= 1000: length 1, 10, 100 m gives {strip}; unbounded length, unbounded count")
print(f"mistake, m >= 1 counted once: {distinct}; mistake, + rim term on a clamped rim: {w3:.2f} against {N1}")
print(f"figure, side 0.25 m, {fig[0]} squares inside, {fig[1]} meeting; scale 160 px per m, centre (210, 210), radius 160 px")
assert N1 == N2 == 232                                                         # two roads, one count
assert abs(J(5, 20) - miller(20, 5)[5]) < 1e-10                                # two Bessel roads agree
assert abs(j01 - 2.404825557695773) < 1e-9                                   # j01 against its tabulated value
assert abs(miller(j01, 0)[0]) < 1e-9                                          # road 2 vanishes at road 1's zero
assert abs(N1 - w2) < abs(N1 - w1) / 5                                          # rim term helps, clamped
assert abs(NN1 - w3) < 3                                                        # rim term helps, free rim
assert lsq[0] <= lre[0] <= wl2 and wl1 <= lre[1] <= lsq[1]                    # L-shape estimate inside both brackets
assert PI * PI / 2 < j01 ** 2 < PI * PI                                         # domain monotonicity
assert strip[2] > 9 * strip[1] > 81 * strip[0]                                 # count grows with length
print("ALL CHECKS PASS")
