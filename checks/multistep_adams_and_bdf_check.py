# Multistep methods: the check behind the card.  Standard library only.
# A satellite on an orbit 400 km up at perigee and 1,600 km up at apogee, stepped by
# Adams-Bashforth (AB4), by AB4 + Adams-Moulton as predictor-corrector (PECE) and by RK4.
# After one period the satellite is back at perigee, so the true error needs no solver.
from fractions import Fraction as Fr
from math import sqrt, pi, log2, log10
from functools import reduce

def e(x):                                   # 1.23e-5 style, the same in Rust
    m, p = f"{x:.2e}".split("e"); return f"{m}e{int(p)}"

def basis(nodes, j):                        # Lagrange basis l_j(s), coefficients low to high
    c = [Fr(1)]
    for m, cm in enumerate(nodes):
        if m != j:
            d = Fr(nodes[j] - cm)
            c = [(c[k - 1] if k else 0) / d - (c[k] * cm / d if k < len(c) else 0) for k in range(len(c) + 1)]
    return c
def adams(nodes):                           # weight j = area under l_j over the next step, s = 0 to 1
    return [sum(a / (k + 1) for k, a in enumerate(basis(nodes, j))) for j in range(len(nodes))]
def bdf(nodes):                             # weight j = slope of l_j at s = 1
    return [sum(k * a for k, a in enumerate(basis(nodes, j)) if k) for j in range(len(nodes))]
def errconst(w, nodes, p):                  # leading local error, times h^(p+1) y^(p+1)
    fact = 1
    for k in range(2, p + 1): fact *= k
    return Fr(1, (p + 1) * fact) - sum(b * Fr(c) ** p for b, c in zip(w, nodes)) / fact

ABN, AMN = [0, -1, -2, -3], [1, 0, -1, -2]
AB, AM, B2, AB6 = adams(ABN), adams(AMN), bdf([1, 0, -1]), adams([0, -1, -2, -3, -4, -5])
print("AB4 weights x24:", [int(w * 24) for w in AB], " AM4 weights x24:", [int(w * 24) for w in AM])
print("BDF2 coefficients of y_(n+1), y_n, y_(n-1):", ", ".join(str(w) for w in B2))
assert AB == [Fr(55, 24), Fr(-59, 24), Fr(37, 24), Fr(-9, 24)]       # the published weights
assert AM == [Fr(9, 24), Fr(19, 24), Fr(-5, 24), Fr(1, 24)]
for nodes, w in ((ABN, AB), (AMN, AM)):     # road 2: the rule is exact for t^0 .. t^3
    assert all(sum(b * Fr(c) ** k for b, c in zip(w, nodes)) == Fr(1, k + 1) for k in range(4))
CAB, CAM = errconst(AB, ABN, 4), errconst(AM, AMN, 4)
print(f"error constants: AB4 {CAB}, AM4 {CAM}, size ratio {float(CAB / -CAM):.2f}; Milne factor {abs(CAM) / (CAB - CAM)}")
assert (CAB, CAM) == (Fr(251, 720), Fr(-19, 720))

def roots2(a, b, c):                        # real roots of a z^2 + b z + c
    d = sqrt(b * b - 4 * a * c); return sorted([(-b - d) / (2 * a), (-b + d) / (2 * a)])
rb, ru = roots2(1.5, -2.0, 0.5), roots2(1.0, 4.0, -5.0)
print(f"roots of rho: Adams z^4 - z^3: 0, 0, 0, 1; BDF2: {rb[0]:.4f}, {rb[1]:.4f}; unstable 2-step: {ru[0]:.4f}, {ru[1]:.4f}")
assert abs(rb[0] - 1 / 3) < 1e-15
assert abs(ru[0] + 5) < 1e-15

MU, RP, RA = 398600.4418, 6778.0, 7978.0    # km^3/s^2 (Earth); perigee and apogee radius, km
A = (RP + RA) / 2; V, T = sqrt(MU * (2 / RP - 1 / A)), 2 * pi * sqrt(A * A * A / MU)
print(f"orbit: perigee speed {V:.4f} km/s, period {T:.1f} s = {T / 60:.2f} min")
NEV = [0]
def f(u):                                   # slope of (x, y, vx, vy): velocity, then gravity
    NEV[0] += 1; x, y, vx, vy = u; r = sqrt(x * x + y * y); k = -MU / (r * r * r)
    return [vx, vy, k * x, k * y]
def lin(u, h, ws, fs):                      # u + h * sum of w_j f_j, added in order as in Rust
    return [u[i] + h * reduce(lambda s, wg: s + wg[0] * wg[1][i], zip(ws, fs), 0.0) for i in range(4)]
def rk4(u, h):
    k1 = f(u); k2 = f(lin(u, h / 2, [1], [k1])); k3 = f(lin(u, h / 2, [1], [k2])); k4 = f(lin(u, h, [1], [k3]))
    return lin(u, h / 6, [1, 2, 2, 1], [k1, k2, k3, k4])
def euler(u, h): return lin(u, h, [1], [f(u)])
U0 = [RP, 0.0, 0.0, V]
def miss(u, c=U0): return sqrt((u[0] - c[0]) * (u[0] - c[0]) + (u[1] - c[1]) * (u[1] - c[1]))  # km from c
def run(N, how, start=rk4, wab=AB, upto=None, ref=U0):
    NEV[0] = 0; h = T / N; u = U0
    if how == "rk4":
        for _ in range(N): u = rk4(u, h)
        return miss(u, ref), NEV[0]
    k = len(wab) if how != "bad" else 2
    us = [u]
    for _ in range(k - 1): us.append(start(us[-1], h))
    fs = [f(w) for w in us][::-1]           # stored slopes, newest first
    ys = us[::-1]; u = us[-1]
    for n in range(k - 1, N if upto is None else upto):
        if how == "bad":                    # y+ = -4 y_n + 5 y_(n-1) + h (4 f_n + 2 f_(n-1))
            p = [-4 * ys[0][i] + 5 * ys[1][i] + h * (4 * fs[0][i] + 2 * fs[1][i]) for i in range(4)]
        else:
            p = lin(u, h, [float(w) for w in wab], fs)
            if how == "pece": p = lin(u, h, [float(w) for w in AM], [f(p)] + fs[:3])
        fs = [f(p)] + fs[:len(fs) - 1]; ys = [p] + ys[:1]; u = p
    return miss(u, ref), NEV[0]

print(" steps   h (s)   AB4 miss km  evals  PECE miss km  evals   RK4 miss km  evals")
res, NS = {}, (100, 200, 400, 800, 1600)
for N in NS:
    res[N] = [run(N, m) for m in ("ab4", "pece", "rk4")]
    print(f"{N:6d} {T / N:7.2f}  " + "  ".join(f"{e(a):>11} {n:6d}" for a, n in res[N]))
for j, m in enumerate(("AB4", "PECE", "RK4")):
    o = [log2(res[N][j][0] / res[2 * N][j][0]) for N in NS[:-1]]
    print(f"observed order {m:4}: " + ", ".join(f"{q:.2f}" for q in o) + "   (theory 4)")
    assert abs(o[-1] - 4) < 0.25
ab, pc = res[400][0][0], res[400][1][0]
print(f"400 steps: AB4 misses by {ab * 1000:.1f} m, PECE by {pc * 1000:.2f} m, ratio {ab / pc:.1f}")
assert 10 < ab / pc < 20
print(f"order 4 predicts AB4 at 800 steps: {ab * 1000:.1f} m / 16 = {ab * 1000 / 16:.2f} m; measured {res[800][0][0] * 1000:.2f} m")
a6 = run(400, "ab6", wab=AB6)
print(f"AB6 weights x1440: {[int(w * 1440) for w in AB6]}; 400 steps: miss {e(a6[0])} km, {a6[1]} evals")
assert a6[0] < ab / 100
print("chart, log10 h:", " ".join(f"{log10(T / N):.2f}" for N in NS[::-1]))
for j, m in enumerate(("AB4", "PECE", "RK4")):
    print(f"chart, log10 miss {m}:", " ".join(f"{log10(res[N][j][0]):.2f}" for N in NS[::-1]))
FN = (3200, 6400, 12800, 25600, 51200, 102400)  # finer steps, down to where rounding stops the fall
fine = [[run(N, m)[0] for m in ("ab4", "pece", "rk4")] for N in FN]
for N, r in zip(FN, fine): print(f"finer, {N:6d} steps: AB4 {e(r[0])}, PECE {e(r[1])}, RK4 {e(r[2])} km")
assert all(1e-11 < min(r[j] for r in fine) < fine[-1][j] / 2 for j in range(3))   # rounding stops the fall

# the picture: AB4's cubic through four stored slopes, with a step stretched to T/8
H, pts = T / 8, [U0]
for q in range(16):                         # reference: RK4 with 200 small steps per quarter step
    u = pts[-1]
    for _ in range(200): u = rk4(u, H / 800)
    pts.append(u)
ap = sqrt((pts[16][0] + RA) * (pts[16][0] + RA) + pts[16][1] * pts[16][1])
print(f"reference at half a period: {e(ap)} km from apogee (Kepler: it is at apogee)")
assert ap < 1e-6
vx, L = [p[2] for p in pts], [basis(ABN, j) for j in range(4)]
st = [vx[12], vx[8], vx[4], vx[0]]          # stored slopes of x, newest first
cub = [sum(float(sum(a * Fr(q - 12, 4) ** k for k, a in enumerate(L[j]))) * st[j] for j in range(4)) for q in range(17)]
print("chart, minutes:", " ".join(f"{q * H / 240:.1f}" for q in range(17)))
print("chart, true vx km/s:", " ".join(f"{v:.2f}" for v in vx))
print("chart, cubic km/s:  ", " ".join(f"{v:.2f}" for v in cub))
inc = H * sum(float(b) * s for b, s in zip(AB, st))
print(f"stretched step: AB4 moves x by {inc:.1f} km, the reference by {pts[16][0] - pts[12][0]:.1f} km")
assert all(abs(cub[q] - vx[q]) < 1e-9 for q in (0, 4, 8, 12))
assert abs(cub[16] - vx[16]) > 1

# what breaks
R10 = U0                                    # reference at T/10: RK4 with 1,600 small steps
for _ in range(1600): R10 = rk4(R10, T / 16000)
for N, at in ((100, 10), (200, 20), (400, 40), (800, 80)):
    print(f"unstable 2-step, h = {T / N:.2f} s: miss after {T * at / N:.1f} s = {e(run(N, 'bad', upto=at, ref=R10)[0])} km")
b1, b2 = run(100, "bad", upto=10, ref=R10)[0], run(200, "bad", upto=20, ref=R10)[0]
assert b2 > 100 * b1
eu = [run(N, "ab4", start=euler)[0] for N in (400, 800)]
print(f"AB4 started by Euler: 400 steps {e(eu[0])} km, 800 steps {e(eu[1])} km, order {log2(eu[0] / eu[1]):.2f}")
assert abs(log2(eu[0] / eu[1]) - 2) < 0.3
print("ALL CHECKS PASS")
