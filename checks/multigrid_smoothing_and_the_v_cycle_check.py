# Multigrid: smooth on the fine grid, correct on the coarse grid -- the check behind the card.
# Standard library only.  Part 1: the bar, -u'' = f on (0, 1) with u = 0 at both ends.  Part 2: the
# 1 m plate, -(u_xx + u_yy) = f with 0 C edges, heated so the exact answer is 100 sin(pi x) sin(pi y) C.
from math import sin, pi, sqrt, log, log10
M64 = (1 << 64) - 1
def splitmix(s):                            # SplitMix64: new state and a value in [-1, 1)
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, ((z ^ (z >> 31)) >> 11) / 2.0 ** 52 - 1.0
def norm(v): return sqrt(sum(x * x for x in v))
def mC(x): return f"{1000 * x:10.5f}"    # an error in C, printed in thousandths of a degree
# ---- the bar: u holds the inside values; both ends are 0 ----
def jacobi1(u, f, h, w):                    # one weighted-Jacobi sweep
    p = [0.0] + u + [0.0]
    return [p[i + 1] + w * 0.5 * (h * h * f[i] + p[i] + p[i + 2] - 2.0 * p[i + 1]) for i in range(len(u))]
def resid1(u, f, h):                        # residual r = f - A u
    p = [0.0] + u + [0.0]
    return [f[i] - (2.0 * p[i + 1] - p[i] - p[i + 2]) / (h * h) for i in range(len(u))]
def restrict1(r, inject=False):             # coarse point j sits on fine point 2j+1
    return r[1::2] if inject else [0.25 * (r[2 * j] + 2.0 * r[2 * j + 1] + r[2 * j + 2]) for j in range(len(r) // 2)]
def prolong1(e):                            # linear interpolation, coarse to fine
    p = [0.0] + e + [0.0]
    return [x for j in range(len(e) + 1) for x in (0.5 * (p[j] + p[j + 1]), p[j + 1])][:-1]
def cycle1(u, f, h, w=2 / 3, nu=(1, 1), gamma=1, inject=False):
    if len(u) == 1: return [0.5 * h * h * f[0]]          # one unknown: solve it exactly
    for _ in range(nu[0]): u = jacobi1(u, f, h, w)       # pre-smooth
    rc = restrict1(resid1(u, f, h), inject); ec = [0.0] * len(rc)
    for _ in range(gamma): ec = cycle1(ec, rc, 2 * h, w, nu, gamma, inject)   # coarse correction
    u = [a + b for a, b in zip(u, prolong1(ec))]
    for _ in range(nu[1]): u = jacobi1(u, f, h, w)       # post-smooth
    return u
def rate1(n, K=10, **kw):                   # K cycles from a random start with f = 0, so u is the error
    s, u = 2026, []
    for _ in range(n): s, x = splitmix(s); u.append(x)
    hist = [norm(u)]
    for _ in range(K): u = cycle1(u, [0.0] * n, 1.0 / (n + 1), **kw); hist.append(norm(u))
    return hist, (hist[-1] / hist[-6]) ** 0.2          # mean factor over the last 5 cycles
# ---- 1. one sweep on the mode sin(k pi x): measured shrink against 1 - 2w sin^2(theta/2) ----
n, h, w, worst = 63, 1.0 / 64, 2.0 / 3.0, 0.0; print("mode k  theta/pi  formula   measured   (one sweep, w = 2/3, n = 63)")
for k in (1, 8, 16, 32, 48, 63):
    v, g = [sin(k * pi * (i + 1) * h) for i in range(n)], 1.0 - 2.0 * w * sin(k * pi * h / 2) ** 2
    meas = norm(jacobi1(v, [0.0] * n, h, w)) / norm(v); worst = max(worst, abs(meas - abs(g)))
    print(f"{k:6d} {k * h:9.4f} {g:9.5f} {meas:9.5f}")
hi = max(abs(1.0 - 2.0 * w * sin(k * pi * h / 2) ** 2) for k in range(32, 64)); print(f"largest high-mode factor, k = 32..63     {hi:.6f}")
print("chart theta/pi     " + " ".join(f"{t / 10:4.1f}" for t in range(11)))
for ww in (2 / 3, 1.0):
    print(f"chart |g|, w = {ww:.2f} " + " ".join(f"{abs(1 - 2 * ww * sin(t * pi / 20) ** 2):4.2f}" for t in range(11)))
for ww in (2 / 3, 0.8):                      # plate: g = 1 - w (s1 + s2); high = some angle >= pi/2
    sm = max(abs(1 - ww * (sin(a * pi / 80) ** 2 + sin(b * pi / 80) ** 2)) for a in range(41) for b in range(41) if max(a, b) >= 20)
    print(f"plate smoothing factor, w = {ww:.2f}        {sm:.6f}")
# ---- 2. Galerkin coarse operator R A P on 7 points, against the 3-point grid's own matrix ----
Ah = lambda v: [-x / 64.0 for x in resid1(v, [0.0] * 7, 0.125)]      # h^2 A v, h = 1/8
RAP = [[4.0 * x for x in restrict1(Ah(prolong1([1.0 if i == j else 0.0 for i in range(3)])))] for j in range(3)]
print("(2h)^2 R A P, middle column:   " + " ".join(f"{x:5.2f}" for x in RAP[1]))
# ---- 3. two-grid factor by Fourier analysis against measured cycles ----
tg = lambda w: max(s * (1 - 2 * w * s) ** 2 + (1 - s) * (1 - 2 * w * (1 - s)) ** 2 for s in (sin(k * pi / 2048) ** 2 for k in range(1, 1024)))
fourier = tg(w); print(f"two-grid factor, Fourier, w = 2/3        {fourier:.6f}"); hists, rates = {}, {}
for n in (63, 255, 1023):
    hists[n], rates[n] = rate1(n); print(f"V(1,1) factor per cycle, n = {n:4d}        {rates[n]:.6f}")
    print(f"chart log10 error, n = {n:4d}" + " ".join(f"{log10(e / hists[n][0]):6.2f}" for e in hists[n][::2]))
other = [("V(2,1) factor, n = 1023", dict(nu=(2, 1))), ("W(1,1) factor, n = 1023", dict(gamma=2)),
         ("wrong: plain Jacobi, w = 1", dict(w=1.0)), ("wrong: injection, not full weighting", dict(inject=True)),
         ("wrong: no smoothing at all", dict(nu=(0, 0))), ("long run: injection, cycles 146 to 150", dict(inject=True, K=150))]
res = {label: rate1(1023, **kw)[1] for label, kw in other}
for label in res: print(f"{label:<40} {res[label]:.6f}")
slow = [sin(pi * (i + 1) / 1024) - sin(1023 * pi * (i + 1) / 1024) for i in range(1023)]   # waves k = 1 and k = 1023 together
lr1 = norm(cycle1(slow, [0.0] * 1023, 1 / 1024, w=1.0)) / norm(slow); print(f"long run: plain Jacobi, slowest pair     {lr1:.6f}, two-grid {tg(1.0):.6f}\nJacobi alone, n = 1023, factor per sweep {1 - 2 * w * sin(pi / 2048) ** 2:.9f}")
FL = [0]        # ---- 4. the plate: grids are lists of rows with a border of zeros; FL counts + - * / kernel by kernel ----
def grid(m): return [[0.0] * (m + 2) for _ in range(m + 2)]
def smooth2(u, f, h, w):                    # weighted Jacobi, 9 flops a point
    m, h2, w4, R = len(u) - 2, h * h, 0.25 * w, range(1, len(u) - 1); out = [u[0]]
    for i in R:
        a, b, c, fr = u[i - 1], u[i], u[i + 1], f[i]
        out.append([0.0] + [b[j] + w4 * (h2 * fr[j] + a[j] + c[j] + b[j - 1] + b[j + 1] - 4.0 * b[j]) for j in R] + [0.0])
    FL[0] += 9 * m * m; return out + [u[-1]]
def resid2(u, f, h):                        # r = f - A u, 7 flops a point
    m, q, R = len(u) - 2, 1.0 / (h * h), range(1, len(u) - 1); out = [[0.0] * (m + 2)]
    for i in R:
        a, b, c, fr = u[i - 1], u[i], u[i + 1], f[i]
        out.append([0.0] + [fr[j] - q * (4.0 * b[j] - a[j] - c[j] - b[j - 1] - b[j + 1]) for j in R] + [0.0])
    FL[0] += 7 * m * m; return out + [[0.0] * (m + 2)]
def restrict2(r):                           # full weighting, 1-2-1 by 1-2-1 over 16, 11 flops a point
    mc = (len(r) - 3) // 2; out = grid(mc)
    for I in range(1, mc + 1):
        a, b, c = r[2 * I - 1], r[2 * I], r[2 * I + 1]
        out[I] = [0.0] + [0.0625 * (a[k - 1] + a[k + 1] + c[k - 1] + c[k + 1] + 2.0 * (a[k] + c[k] + b[k - 1] + b[k + 1])
                                    + 4.0 * b[k]) for k in range(2, 2 * mc + 1, 2)] + [0.0]
    FL[0] += 11 * mc * mc; return out
def prolong_add(u, e):                      # bilinear interpolation of e, added into u
    mc = len(e) - 2; m = 2 * mc + 1
    for I in range(mc + 1):
        e0, e1 = e[I], e[I + 1]; ra, rb = [0.0] * (m + 2), [0.0] * (m + 2)
        for J in range(mc + 1):
            ra[2 * J], ra[2 * J + 1] = e0[J], 0.5 * (e0[J] + e0[J + 1])
            rb[2 * J], rb[2 * J + 1] = 0.5 * (e0[J] + e1[J]), 0.25 * (e0[J] + e0[J + 1] + e1[J] + e1[J + 1])
        if I > 0: u[2 * I] = [x + y for x, y in zip(u[2 * I], ra)]
        u[2 * I + 1] = [x + y for x, y in zip(u[2 * I + 1], rb)]
    FL[0] += 8 * (mc + 1) ** 2 + m * m; return u
def vcycle2(u, f, h, w=0.8):
    if len(u) == 3: return [[0.0] * 3, [0.0, 0.25 * h * h * f[1][1], 0.0], [0.0] * 3]
    u = smooth2(u, f, h, w); rc = restrict2(resid2(u, f, h))
    u = prolong_add(u, vcycle2(grid(len(rc) - 2), rc, 2 * h, w)); return smooth2(u, f, h, w)
def heat(m):                                # sin(pi x) at the grid lines, and f = 200 pi^2 sin sin
    s = [sin(pi * i / (m + 1)) for i in range(m + 2)]; return s, [[200.0 * pi * pi * a * b for b in s] for a in s]
def fmg(m, per_level):                      # full multigrid: solve coarse, interpolate, cycle, repeat
    u = grid(1)
    for L in range(1, round(log(m + 1, 2)) + 1):
        mm = 2 ** L - 1; s, f = heat(mm)
        if mm > 1: u = prolong_add(grid(mm), u)
        for _ in range(per_level): u = vcycle2(u, f, 1.0 / (mm + 1), 0.8)
    return u, s
print("plate     N    V flops/N  V/finest  FMG flops/N  alg err mC disc err mC total err mC"); plate = {}
for m in (63, 255, 1023):
    _, f = heat(m); FL[0] = 0; vcycle2(grid(m), f, 1.0 / (m + 1)); vflops = FL[0]
    FL[0] = 0; vcycle2(grid((m - 1) // 2), heat((m - 1) // 2)[1], 2.0 / (m + 1)); vratio = vflops / (vflops - FL[0])
    FL[0] = 0; u, s = fmg(m, 2); N = m * m
    beta = (pi / (2 * m + 2)) ** 2 / sin(pi / (2 * m + 2)) ** 2        # closed form: u_h = 100 beta sin sin
    alg = max(abs(u[i][j] - 100 * beta * s[i] * s[j]) for i in range(m + 2) for j in range(m + 2))
    tot = max(abs(u[i][j] - 100 * s[i] * s[j]) for i in range(m + 2) for j in range(m + 2))
    plate[m] = (vflops / N, vratio, FL[0] / N, alg, 100 * (beta - 1), tot, FL[0], u[(m + 1) // 2][(m + 1) // 2])
    print(f"{m:5d} {N:8d} {vflops / N:9.3f} {vratio:9.4f} {FL[0] / N:11.3f}" + mC(alg) + " " + mC(100 * (beta - 1)) + "  " + mC(tot))
u1, _ = fmg(1023, 1); one = abs(u1[512][512] - 100 * (pi / 2048) ** 2 / sin(pi / 2048) ** 2)
print(f"plate centre after FMG, 1023^2           {plate[1023][7]:.6f} C (exact 100)\nFMG flops for 1,046,529 unknowns         {plate[1023][6]}")
wf = 2 * 9 + 7 + 11 / 4 + 8 / 4 + 1                   # finest-level flops a point: 2 smooths, residual, restrict, interpolate
print(f"work model: finest {wf:.2f}, V x4/3 {4 / 3 * wf:.2f}, FMG {4 / 3 * (2 * 4 / 3 * wf + 3):.2f}, Cholesky/FMG {1046529 * 1023 ** 2 / plate[1023][6]:.0f}")
print("wrong: one V-cycle per level, centre err" + mC(one) + " mC")
print(f"estimate: band Cholesky, N m^2 flops     {1046529 * 1023 ** 2 / 1e12:.1f}e12\nestimate: plate Jacobi sweeps per digit  {log(10) / -log(1 - 2 * sin(pi / 2048) ** 2):.0f}")
assert worst < 1e-12, "measured shrink of each mode equals 1 - 2w sin^2(theta/2)"
assert abs(hi - 1 / 3) < 1e-12, "every high mode shrinks by at least 1/3"
assert RAP[1] == [-1.0, 2.0, -1.0], "Galerkin R A P equals the coarse grid's own matrix"
assert abs(fourier - 1 / 9) < 1e-12, "two-grid factor is exactly 1/9 for every mode pair"
assert abs(res["W(1,1) factor, n = 1023"] - 1 / 9) < 0.01, "W-cycle measures the two-grid factor"
assert max(rates.values()) - min(rates.values()) < 0.02 and max(rates.values()) < 0.25, "V rate free of n"
assert res["wrong: plain Jacobi, w = 1"] > 0.9 and abs(lr1 - tg(1.0)) < 1e-9, "w = 1: the slowest pair keeps (1 - 2s)^2 a cycle"
assert res["long run: injection, cycles 146 to 150"] > 0.7 > res["wrong: injection, not full weighting"], "injection's early average flatters it"
assert all(plate[m][1] < 4 / 3 + 0.01 and plate[m][0] <= 4 / 3 * wf for m in plate), "counted V work within 4/3 of finest level"
assert plate[1023][3] < plate[1023][4], "FMG algebraic error below the closed-form discretisation error"
assert one > 10 * plate[1023][4], "one V-cycle per level stops short of discretisation accuracy"
print("ALL CHECKS PASS")
