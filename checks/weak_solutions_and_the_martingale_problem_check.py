# Weak solutions and the martingale problem -- the check behind the card.  Only math is imported.
# Tanaka's equation dX = sgn(X) dW from X0 = 0 over one year, with sgn(0) = -1.
# Roads: a four-step path by hand; X = B and Y = -B rebuilt from W = sum sgn(B) dB on
# simulated paths; the law of W against the normal CDF (Levy); the Euler scheme driven by
# one W on nested grids (the size settles, the sign never does); and the martingale
# problem for L f = f''/2 on f = x^2 and x^4.  SplitMix64 and Box-Muller, seed 20261123.
# Each simulated path serves as B in road 2 and as W in roads 3 and 4.
import math

def sgn(x, s0=-1.0):
    return 1.0 if x > 0 else (-1.0 if x < 0 else s0)

def noise(x):  # the noise size in road 3's Euler scheme
    return sgn(x)

def Phi_series(z):  # the erf Taylor series
    s, term, k = 0.0, z / math.sqrt(2), 0
    while abs(term) > 1e-17:
        s += term / (2 * k + 1)
        k += 1
        term *= -z * z / 2 / k
    return 0.5 + s / math.sqrt(math.pi)

def Phi_simpson(z, m=2000):  # Simpson's rule on the bell curve from 0 to z
    h = z / m
    f = lambda x: math.exp(-x * x / 2) / math.sqrt(2 * math.pi)
    s = f(0) + f(z) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, m))
    return 0.5 + s * h / 3

M64 = (1 << 64) - 1
state = 20261123
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def gauss():
    return math.sqrt(-2 * math.log(unif())) * math.cos(2 * math.pi * unif())

# ---- road 1: one path by hand, four quarter-year steps ----
dB = [0.3, -0.5, 0.4, 0.6]
B = [0.0]
for d in dB: B.append(B[-1] + d)
dW = [sgn(B[k]) * dB[k] for k in range(4)]
xb = sum(sgn(B[k]) * dW[k] for k in range(4))
yb = sum(sgn(-B[k]) * dW[k] for k in range(4))
print("hand: B at t = 0, 0.25, 0.5, 0.75, 1:", " ".join(f"{b:.2f}" for b in B))
print("hand: sgn(B) at the step starts:", " ".join(f"{sgn(b):.0f}" for b in B[:4]))
print("hand: dW = sgn(B) dB:", " ".join(f"{d:.2f}" for d in dW), "; W_1", f"{sum(dW):.2f}")
print(f"hand: sum sgn(B) dW {xb:.4f} against B_1 {B[4]:.4f}")
print(f"hand: sum sgn(-B) dW {yb:.4f} against -B_1 {-B[4]:.4f}; gap {yb + B[4]:.4f} = 2 x first step")
print("hand: dW^2:", " ".join(f"{d * d:.2f}" for d in dW))
print(f"hand: sum dW^2 {sum(d * d for d in dW):.4f} = sum dB^2 {sum(d * d for d in dB):.4f}")
assert abs(xb - B[4]) < 1e-12 and abs((yb + B[4]) - 2 * dB[0]) < 1e-12

# ---- roads 2 to 4: PATHS Brownian paths of NF steps, read at nested grids ----
PATHS, NF, LEVELS = 1000, 4096, [16, 64, 256, 1024, 4096]
gap2 = {n: 0.0 for n in LEVELS}; maxerr = 0.0; minloc = 0.0
w1, wb, loc, s_gap, s_dis = [], [], [], {n: 0.0 for n in LEVELS}, {n: 0 for n in LEVELS}
mp2, mp4, zx = [], [], []
for p in range(PATHS):
    fine = [gauss() / math.sqrt(NF) for _ in range(NF)]
    xend = {}
    for n in LEVELS:
        r = NF // n
        d = [sum(fine[k * r:(k + 1) * r]) for k in range(n)]
        # road 2: this path as B; W = sum sgn(B) dB; rebuild B and -B from W
        b, w, x, y = 0.0, 0.0, 0.0, 0.0
        for k in range(n):
            dw = sgn(b) * d[k]
            x += sgn(b) * dw; y += sgn(-b) * dw
            minloc = min(minloc, abs(b + d[k]) - abs(b) - dw)
            b += d[k]; w += dw
        maxerr = max(maxerr, abs(x - b)); gap2[n] += (y + b) * (y + b)
        if n == NF: w1.append(w); wb.append(w * b); loc.append(abs(b) - w)
        # road 3: this path as W; Euler X_{k+1} = X_k + noise(X_k) dW_k
        X, W, Wmin, sx2, Z = 0.0, 0.0, 0.0, 0.0, 0.0  # Z: the same Euler rule with sgn(0) = 0
        for k in range(n):
            sx2 += X * X / n
            X += noise(X) * d[k]; Z += sgn(Z, 0.0) * d[k]; W += d[k]; Wmin = min(Wmin, W)
        xend[n] = X
        s_gap[n] += abs(abs(X) - (W - Wmin))
        if n == NF: mp2.append(X * X - 1.0); mp4.append(X * X * X * X - 6 * sx2); zx.append(Z)
    for n in LEVELS: s_dis[n] += (xend[n] > 0) != (xend[NF] > 0)

def mean_se(v):
    m = sum(v) / len(v)
    return m, math.sqrt(sum((a - m) * (a - m) for a in v) / (len(v) - 1) / len(v))

print(f"paths {PATHS}, finest grid {NF} steps in one year; errors are standard errors")
print("road 2: n steps | RMS gap of the -B rebuild | 2/sqrt(n)")
for n in LEVELS:
    rms = math.sqrt(gap2[n] / PATHS)
    print(f"  {n:5d} | {rms:.4f} | {2 / math.sqrt(n):.4f}")
    assert abs(rms / (2 / math.sqrt(n)) - 1) < 0.1
print(f"road 2: B rebuilt from W within 1e-9: {maxerr < 1e-9}; every step of |B| - W at least 0: {minloc > -1e-12}")
assert maxerr < 1e-9 and minloc > -1e-12
mw, sw = mean_se(w1); mv, sv = mean_se([a * a for a in w1])
pw, sp = mean_se([1.0 if a <= 1 else 0.0 for a in w1])
mwb, swb = mean_se(wb); ml, sl = mean_se(loc)
p1, p2 = Phi_series(1.0), Phi_simpson(1.0)
print(f"normal CDF at 1: series {p1:.6f}, Simpson {p2:.6f}")
print(f"law of W_1: mean {mw:.4f} +- {sw:.4f}; mean square {mv:.4f} +- {sv:.4f}; P(W_1 <= 1) {pw:.4f} +- {sp:.4f}")
print(f"E[W_1 B_1] {mwb:.4f} +- {swb:.4f} (exact 0); E|B_1| - E W_1 {ml:.4f} +- {sl:.4f} (exact {math.sqrt(2 / math.pi):.4f})")
assert abs(p1 - p2) < 1e-9 and abs(mw) < 4 * sw and abs(mv - 1) < 4 * sv and abs(pw - p1) < 4 * sp
assert abs(mwb) < 4 * swb and abs(ml - math.sqrt(2 / math.pi)) < 4 * sl
print("road 3: n steps | mean gap |X_1| to W_1 - min W | share of signs unlike the 4096-step X_1")
for n in LEVELS:
    print(f"  {n:5d} | {s_gap[n] / PATHS:.4f} | {s_dis[n] / PATHS:.4f}")
    assert n == NF or abs(s_dis[n] / PATHS - 0.5) < 4 * math.sqrt(0.25 / PATHS)
assert s_gap[16] > 4 * s_gap[1024]
a2, e2 = mean_se(mp2); a4, e4 = mean_se(mp4); wrong, ew = mean_se([v - 1.0 for v in mp2])
print("road 4: martingale problem, L f = f''/2, mean of f(X_1) - f(0) - (sum of L f(X_t) dt):")
print(f"  f = x^2: {a2:.4f} +- {e2:.4f}; f = x^4: {a4:.4f} +- {e4:.4f}; both exact 0")
assert abs(a2) < 4 * e2 and abs(a4) < 4 * e4
zmax = max(abs(z) for z in zx); mz = sum(z * z for z in zx) / PATHS
mx, ex = mean_se([v + 1.0 for v in mp2])  # E[X_1^2] with sgn(0) = -1
print(f"mistake: L f = f'' (no half), f = x^2: {wrong:.4f} +- {ew:.4f}, should be 0")
print(f"mistake: sgn(0) = 0 on the same noise: largest |X_1| {zmax:.4f}, so E[X_1^2] = {mz:.4f}, not {mx:.4f} +- {ex:.4f}")
print(f"mistake: hand path, -B rebuilt on the grid: {yb:.4f}, not {-B[4]:.4f}")
assert abs(wrong) > 4 * ew  # the mistake is detectably wrong
assert zmax == 0.0; assert abs(mx - mz) > 4 * ex  # sgn(0) = 0 never leaves 0; sgn(0) = -1 spreads out
print("chart, size gap:", " ".join(f"{s_gap[n] / PATHS:.2f}" for n in LEVELS[:4]))
print("chart, signs unlike:", " ".join(f"{s_dis[n] / PATHS:.2f}" for n in LEVELS[:4]))
print("ALL CHECKS PASS")
