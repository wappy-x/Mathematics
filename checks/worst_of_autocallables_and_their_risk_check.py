# Worst-of autocallable on three house shares -- the check behind the card. Standard library only.
# Road 1: Monte Carlo with a Cholesky factor. Road 2: nested quadrature at correlation 1 (one share).
# Road 3: one-factor quadrature for the last quarter, against Monte Carlo with common random numbers.
import math
R, Q, SIG, T3, PRICE = 0.05, 0.02, 0.20, 3, 98.0   # bank rate, dividend, volatility, years, target price
CALL, KNOCK, OTHERS, TLEFT, BUMP = 100.0, 70.0, 120.0, 0.25, 2.0

def ncdf(x):   # normal CDF from a written-out erfc (Chebyshev fit, error below 1.2e-7)
    z = abs(x) / math.sqrt(2); t = 1 / (1 + 0.5 * z)
    e = t * math.exp(-z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (0.09678418 + t * (-0.18628806
        + t * (0.27886807 + t * (-1.13520398 + t * (1.48851587 + t * (-0.82215223 + t * 0.17087277)))))))))
    return 1 - 0.5 * e if x >= 0 else 0.5 * e

def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

class Rng:     # splitmix64 uniforms, Box-Muller normals
    def __init__(s, seed): s.x, s.spare = seed, None
    def u(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF; z = s.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
    def g(s):
        if s.spare is not None: v, s.spare = s.spare, None; return v
        a, b = math.sqrt(-2 * math.log(s.u())), 2 * math.pi * s.u(); s.spare = a * math.sin(b); return a * math.cos(b)

def cholesky(rho):  # 3 by 3, every pair at rho
    L = [[0.0] * 3 for _ in range(3)]
    for i in range(3):
        for j in range(i + 1):
            s = (1.0 if i == j else rho) - sum(L[i][k] * L[j][k] for k in range(j))
            L[i][j] = math.sqrt(s) if i == j else s / L[j][j]
    return L

def mean_se(xs):
    m = sum(xs) / len(xs); return m, math.sqrt(sum((x - m) * (x - m) for x in xs) / (len(xs) - 1) / len(xs))

def note_mc(rho, n, seed=2026):  # per path: (value of the note with no coupon, discounted coupon-years)
    L = cholesky(rho) if rho < 1 else [[1, 0, 0], [1, 0, 0], [1, 0, 0]]; g = Rng(seed); out = []
    for _ in range(n):
        x = [0.0] * 3; done = None
        for yr in range(1, T3 + 1):
            z = [g.g() for _ in range(3)]
            x = [x[i] + R - Q - 0.5 * SIG * SIG + SIG * sum(L[i][k] * z[k] for k in range(3)) for i in range(3)]
            w = 100 * math.exp(min(x)); df = math.exp(-R * yr)
            if done is None and w >= CALL: done = (100 * df, yr * df)
        out.append(done or (df * (100 if w >= KNOCK else w), 0.0))
    return out

def fair(paths):   # value is A + 100 c B on every path, so the fair coupon solves one line
    A, B = (sum(p[k] for p in paths) / len(paths) for k in (0, 1)); c = (PRICE - A) / (100 * B)
    return A, B, c, mean_se([a + 100 * c * b for a, b in paths])[1] / (100 * B)

def note_rho1(c, n=200):   # one share, backwards: closed form in the last year, Simpson before that
    mu, df = R - Q - 0.5 * SIG * SIG, math.exp(-R)
    def up(s, k): return ncdf((math.log(s / k) + mu) / SIG)
    def v2(s): return df * ((100 + 300 * c) * up(s, CALL) + 100 * (up(s, KNOCK) - up(s, CALL))
                            + s * math.exp(R - Q) * (1 - ncdf((math.log(s / KNOCK) + mu) / SIG + SIG)))
    def roll(s, k, vnext):
        zs = (math.log(CALL / s) - mu) / SIG
        tail = simpson(lambda z: vnext(s * math.exp(mu + SIG * z)) * math.exp(-z * z / 2), -8, zs, n)
        return df * ((100 + 100 * k * c) * up(s, CALL) + tail / math.sqrt(2 * math.pi))
    return roll(100.0, 1, lambda s: roll(s, 2, v2))

def quad(levels, sigs, c, rho=0.5, nm=100, nx=100):   # last quarter: condition on the shared factor
    a, b = math.sqrt(rho), math.sqrt(1 - rho)
    def given(m):
        mus = [math.log(l / 100) + (R - Q - 0.5 * s * s) * TLEFT + s * math.sqrt(TLEFT) * a * m for l, s in zip(levels, sigs)]
        sds = [s * math.sqrt(TLEFT) * b for s in sigs]
        def fw(x): return 1 - math.prod(1 - ncdf((math.log(x / 100) - u) / d) for u, d in zip(mus, sds))
        return 100 + 300 * c * (1 - fw(CALL)) - (100 - KNOCK) * fw(KNOCK) - simpson(fw, 1e-6, KNOCK, nx)
    return math.exp(-R * TLEFT) * simpson(lambda m: given(m) * math.exp(-m * m / 2), -8, 8, nm) / math.sqrt(2 * math.pi)

def mc_last(draws, levels, sigs, c):
    def pay(w): return 100 + 300 * c if w >= CALL else (100 if w >= KNOCK else w)
    return [math.exp(-R * TLEFT) * pay(min(l * math.exp((R - Q - 0.5 * s * s) * TLEFT + s * math.sqrt(TLEFT) * z)
            for l, s, z in zip(levels, sigs, d))) for d in draws]

def corr_draws(n, seed, L):
    g = Rng(seed); zs = [[g.g() for _ in range(3)] for _ in range(n)]
    return [[sum(L[i][k] * z[k] for k in range(3)) for i in range(3)] for z in zs]

print("house: three shares, each at its start level 100, vol 20%, dividend 2%, bank 5%; target price 98")
L = cholesky(0.5); print("cholesky at 0.5: rows", " ".join("(" + ", ".join(f"{v:.6f}" for v in row) + ")" for row in L))
assert all(abs(sum(L[i][k] * L[j][k] for k in range(3)) - (1 if i == j else 0.5)) < 1e-12 for i in range(3) for j in range(3))
N3 = 100000; res = {}
for rho in (0.0, 0.3, 0.5, 0.8, 1.0):
    p = note_mc(rho, N3); res[rho] = (p, *fair(p)); A, B, c, se = res[rho][1:]
    print(f"rho {rho:.1f}: no-coupon value {A:.4f}, coupon-years {B:.4f}, fair coupon {100*c:.2f}% (se {100*se:.2f}%)")
c5 = res[0.5][3]; vals = {rho: sum(a + 100 * c5 * b for a, b in res[rho][0]) / N3 for rho in (0.3, 0.5, 0.8, 1.0)}
print("note at the 0.5 fair coupon, by correlation:", ", ".join(f"{k:.1f} -> {v:.4f}" for k, v in vals.items()))
up, dn = (sum(a + 100 * c5 * b for a, b in note_mc(rr, N3)) / N3 for rr in (0.55, 0.45))
print(f"correlation sensitivity at 0.5, common draws: {(up - dn) / 10:+.4f} per 0.01")
A1 = note_rho1(0.0); B1 = (note_rho1(1.0) - A1) / 100; c1 = (PRICE - A1) / (100 * B1)
print(f"rho 1.0 by quadrature: no-coupon value {A1:.4f}, coupon-years {B1:.4f}, fair coupon {100*c1:.2f}%")
assert abs(res[1.0][3] - c1) < 3 * res[1.0][4], "Monte Carlo at correlation 1 misses the one-share quadrature"
assert res[0.3][3] > res[0.5][3] + 5 * res[0.5][4] > res[0.8][3] + 10 * res[0.8][4], "fair coupon not falling in rho"
assert vals[0.3] < vals[0.5] < vals[0.8] and up > dn, "the holder is not long correlation"

print(f"last quarter: other two shares at {OTHERS:.0f}, coupon {100*c5:.2f}%, bump {BUMP:.0f} points, vega per vol point; "
      f"called at year 3 pays {100 + 300 * c5:.2f}, a step of {300 * c5:.2f}")
grid = list(range(56, 114, 3)); rows = {"value": [], "delta": [], "gamma": [], "vega": []}
for lv in grid:
    v, u, d = (quad([lv + s, OTHERS, OTHERS], [SIG] * 3, c5) for s in (0, BUMP, -BUMP))
    rows["value"].append(v); rows["delta"].append((u - d) / (2 * BUMP)); rows["gamma"].append((u - 2 * v + d) / (BUMP * BUMP))
    rows["vega"].append(quad([lv, OTHERS, OTHERS], [SIG + 0.01, SIG, SIG], c5) - v)
print("chart,level," + ",".join(str(x) for x in grid))
for k in rows: print(f"chart,{k}," + ",".join(f"{x:.{2 if k == 'value' else 3}f}" for x in rows[k]))
draws = corr_draws(100000, 77, L); fresh = corr_draws(100000, 78, L); fresh2 = corr_draws(100000, 79, L)
for lv in (62, 74, 89, 107):
    lev = [[lv + s, OTHERS, OTHERS] for s in (0, BUMP, -BUMP)]
    v, u, d = (mc_last(draws, l, [SIG] * 3, c5) for l in lev)
    vg = mc_last(draws, lev[0], [SIG + 0.01, SIG, SIG], c5); i = grid.index(lv)
    de, ga, ve = (mean_se(x) for x in ([(a - b) / (2 * BUMP) for a, b in zip(u, d)],
                  [(a - 2 * b + e) / (BUMP * BUMP) for a, b, e in zip(u, v, d)], [a - b for a, b in zip(vg, v)]))
    print(f"level {lv}: common draws delta {de[0]:.3f} ({de[1]:.3f}), gamma {ga[0]:+.3f} ({ga[1]:.3f}), vega {ve[0]:+.3f} ({ve[1]:.3f})"
          f"; quadrature {rows['delta'][i]:.3f}, {rows['gamma'][i]:+.3f}, {rows['vega'][i]:+.3f}")
    for est, ref in ((de, rows["delta"][i]), (ga, rows["gamma"][i]), (ve, rows["vega"][i])):
        assert abs(est[0] - ref) < 4 * est[1] + 0.002, "common-draw Greek misses the quadrature"
    if lv == 74:
        fu, fd = (mean_se(mc_last(f, l, [SIG] * 3, c5)) for f, l in ((fresh, lev[1]), (fresh2, lev[2])))
        fv, b = mean_se(mc_last(fresh, lev[0], [SIG + 0.01, SIG, SIG], c5)), mean_se(v)
        print(f"mistake, fresh draws for the bumped legs at 74: gamma {(fu[0] - 2 * b[0] + fd[0]) / (BUMP * BUMP):+.3f} "
              f"({math.sqrt(fu[1] * fu[1] + 4 * b[1] * b[1] + fd[1] * fd[1]) / (BUMP * BUMP):.3f}), vega {fv[0] - b[0]:+.3f} ({math.hypot(fv[1], b[1]):.3f})")
        wide = (quad([84, OTHERS, OTHERS], [SIG] * 3, c5) - 2 * rows["value"][i] + quad([64, OTHERS, OTHERS], [SIG] * 3, c5)) / 100
        print(f"mistake, a 10-point bump across the barrier at 74: gamma {wide:+.3f}")
print(f"mistake, price on one share (correlation 1): fair coupon {100*c1:.2f}% against {100*c5:.2f}%")
print(f"mistake, assume independent shares (correlation 0): fair coupon {100*res[0.0][3]:.2f}%")
signs = [g > 0 for g in rows["gamma"]]; flips = [grid[i] for i in range(1, len(grid)) if signs[i] != signs[i - 1]]
print("gamma changes sign between", ", ".join(f"{f - 3} and {f}" for f in flips))
drift = (R - Q + 0.5 * SIG * SIG) * TLEFT; kink = KNOCK * math.exp(-drift - KNOCK / (100 - KNOCK) * SIG * SIG * TLEFT)
print(f"one share: gamma changes sign at {KNOCK * math.exp(-drift):.2f} (pure step at 70), {kink:.2f} (step plus sold call at 70), "
      f"{CALL * math.exp(-drift):.2f} (step at 100)")
ratio = [rows["vega"][grid.index(x)] / (0.01 * SIG * TLEFT * x * x * rows["gamma"][grid.index(x)]) for x in (62, 74, 89, 107)]
print("vega over 0.01 sigma T level^2 gamma at 62, 74, 89, 107:", ", ".join(f"{x:.2f}" for x in ratio))
assert all(0.8 < x < 1.1 for x in ratio), "vega does not follow gamma"
assert len(flips) == 3 and flips[0] - 3 < kink <= flips[0] and flips[2] - 3 < CALL * math.exp(-drift) <= flips[2], "sign changes misplaced"
print("ALL CHECKS PASS")
