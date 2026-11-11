# Proximal gradient on a lasso -- the check behind the card; only math is imported.
# A garden centre explains weekly sales (GBP thousand, measured from the average week) by
# 200 candidate signals over 100 weeks.  Every signal shares half its swing with one
# seasonal factor.  Truth: nine signals matter, noise SD 1.  Minimise
# F(x) = 1/2 |y - Ax|^2 + LAM |x|_1 by ISTA, by FISTA and by coordinate descent.
# The coefficients x are called b below; A[j] is signal j's column.
import math

N, P, LAM, RHO, SEED, K = 100, 200, 40.0, 0.5, 11, 3000
TRUE = [3.0, -2.5, 2.0, -2.0, 1.5, 1.5, -1.2, 1.0, 1.0] + [0.0] * (P - 9)
M64, state = (1 << 64) - 1, SEED

def uniform():                                # SplitMix64: a draw in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) * 2.0 ** -53

def normal():                                 # Box-Muller, cosine half only
    u = uniform()
    return math.sqrt(-2.0 * math.log(u)) * math.cos(2.0 * math.pi * uniform())

def dot(u, v): return sum(a * b for a, b in zip(u, v))
def Ab(b): return [sum(b[j] * A[j][i] for j in range(P) if b[j] != 0.0) for i in range(N)]
def AT(r): return [dot(a, r) for a in A]     # A transpose times r: one number per signal
def F(b): r = [u - v for u, v in zip(Ab(b), y)]; return 0.5 * dot(r, r) + LAM * sum(map(abs, b))
def soft(v, t): return math.copysign(max(abs(v) - t, 0.0), v) + 0.0   # prox of t|.|

def dual_gap(b):                              # F(b) minus a dual value: a bound on F(b) - F*
    r = [u - v for u, v in zip(y, Ab(b))]
    s = min(1.0, LAM / max(map(abs, AT(r))))  # scale r until no |A_j . theta| exceeds LAM
    return F(b) - (0.5 * dot(y, y) - 0.5 * sum((u - s * v) ** 2 for u, v in zip(y, r)))

f = [normal() for _ in range(N)]              # the seasonal factor
A = []                                        # A[j] = signal j over the 100 weeks, standardised
for j in range(P):
    c = [math.sqrt(RHO) * f[i] + math.sqrt(1 - RHO) * normal() for i in range(N)]
    m = sum(c) / N; c = [t - m for t in c]; sd = math.sqrt(dot(c, c) / N)
    A.append([t / sd for t in c])
y = [dot([A[j][i] for j in range(9)], TRUE[:9]) + normal() for i in range(N)]
m = sum(y) / N; y = [t - m for t in y]
v = [1.0] * P                                 # power iteration: L = largest eigenvalue of A'A
for _ in range(200):
    w = AT(Ab(v)); n = math.sqrt(dot(w, w)); v = [t / n for t in w]
L = dot(Ab(v), Ab(v)); al = 1.0 / L
eig_res = math.sqrt(sum((a - L * b) ** 2 for a, b in zip(AT(Ab(v)), v)))
c0 = AT(y)
print(f"setup: {N} weeks, {P} signals, lambda {LAM:.0f} (the regularisation card's {2 * LAM:.0f}), L {L:.2f}, step 1/L {al:.8f}")
print(f"lambda_max = max |A_j . y| = {max(map(abs, c0)):.2f}: at or above it every coefficient is 0; F(0) = {F([0.0] * P):.2f}")

def prox_by_search(v, t):                     # minimise t|x| + (x - v)^2 / 2 by golden section
    lo, hi, g = -abs(v) - 1.0, abs(v) + 1.0, (math.sqrt(5) - 1) / 2
    for _ in range(200):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        if t * abs(a) + (a - v) ** 2 / 2 < t * abs(b) + (b - v) ** 2 / 2: hi = b
        else: lo = a
    return (lo + hi) / 2
print("first ISTA step from x = 0, signals 1, 2, 10, 11:")
for j in (0, 1, 9, 10):
    x1, xs = soft(al * c0[j], al * LAM), prox_by_search(al * c0[j], al * LAM)
    print(f"  signal {j + 1:3d}: A_j.y {c0[j]:8.2f}  step*A_j.y {al * c0[j]:.6f}"
          f"  shrink {al * LAM:.6f}  x_1 {x1:.6f}  by search {xs:.6f}")
kept1 = sum(abs(t) > LAM for t in c0)
print(f"  signals kept after step 1: {kept1} (those with |A_j . y| > {LAM:.0f})")

def run(K, step, thr, momentum, subgrad=False):
    b, z, t, hist, kept = [0.0] * P, [0.0] * P, 1.0, [F([0.0] * P)], {}
    for k in range(K):
        g = AT([u - w for u, w in zip(Ab(z), y)])
        if subgrad: bn = [x - step * (gi + LAM * ((x > 0) - (x < 0))) for x, gi in zip(z, g)]
        else: bn = [soft(x - step * gi, thr) for x, gi in zip(z, g)]
        tn = (1 + math.sqrt(1 + 4 * t * t)) / 2 if momentum else 1.0
        z = [u + (t - 1) / tn * (u - w) for u, w in zip(bn, b)]
        b, t = bn, tn; hist.append(F(b)); kept[k + 1] = sum(x != 0.0 for x in b)
    return b, hist, kept

def cd(sweeps):                               # road 2: coordinate descent, one signal at a time
    b, r, nn, hist = [0.0] * P, y[:], [dot(a, a) for a in A], [F([0.0] * P)]
    for s in range(sweeps):
        for j in range(P):
            new = soft(dot(A[j], r) + nn[j] * b[j], LAM) / nn[j]
            if new != b[j]: r = [ri - (new - b[j]) * a for ri, a in zip(r, A[j])]; b[j] = new
        hist.append(F(b))
    return b, hist

bi, Hi, ki = run(K, al, al * LAM, False)
bf, Hf, kf = run(K, al, al * LAM, True)
bstar, Hc = cd(300)
Fs, gs = F(bstar), dual_gap(bstar)
d0 = dot(bstar, bstar)                        # |b_0 - b*|^2 with b_0 = 0
def first(H): return next((str(k) for k, h in enumerate(H) if h - Fs < 1e-6), "none")
def lg(x): return math.log10(max(x, 1e-16))      # log10, floored where the gap is exactly 0
print(f"F* = {Fs:.6f}, certified: dual gap {gs:.12f}")
print(f"first within 0.000001 of F*: ISTA step {first(Hi)}, FISTA step {first(Hf)},"
      f" coordinate descent sweep {first(Hc)}")
print("   k  kept: ISTA  FISTA")
for k in (1, 10, 50, 100, 200, 500, 1000):
    print(f"{k:4d} {ki[k]:11d} {kf[k]:6d}")
print("   k  log10 gap: ISTA  FISTA | log10 bound: ISTA  FISTA")
for k in (1, 10, 100, 1000, 3000):
    print(f"{k:4d} {lg(Hi[k] - Fs):16.2f} {lg(Hf[k] - Fs):6.2f} |"
          f" {math.log10(L * d0 / (2 * k)):17.2f} {math.log10(2 * L * d0 / (k + 1) ** 2):6.2f}")
ks = list(range(0, 2001, 200))
print("chart, k     ", " ".join(f"{k:6d}" for k in ks))
print("chart, ISTA  ", " ".join(f"{lg(Hi[k] - Fs):6.2f}" for k in ks))
print("chart, FISTA ", " ".join(f"{lg(Hf[k] - Fs):6.2f}" for k in ks))
print(f"steps where F rose, of the first 1000: ISTA {sum(Hi[k + 1] > Hi[k] for k in range(1000))},"
      f" FISTA {sum(Hf[k + 1] > Hf[k] for k in range(1000))}")
kkt = max(abs(g - LAM * math.copysign(1, b)) if b != 0.0 else max(abs(g) - LAM, 0.0)
          for b, g in zip(bstar, AT([u - w for u, w in zip(y, Ab(bstar))])))
gap_cd = max(abs(a - b) for a, b in zip(bf, bstar))
print(f"optimality conditions at coordinate descent's answer, worst miss: {kkt:.9f}")
print(f"FISTA against coordinate descent, largest coefficient gap: {gap_cd:.9f}")
print(f"kept: FISTA {sum(t != 0.0 for t in bf)}, ISTA {sum(t != 0.0 for t in bi)},"
      f" coordinate descent {sum(t != 0.0 for t in bstar)}")
for j in range(P):
    if bf[j] != 0.0:
        print(f"  signal {j + 1:3d}  " + f"{'#' * round(10 * abs(bf[j])):<28}" + f"  {bf[j]:5.2f}  true {TRUE[j]:5.2f}")
print(f"F* splits as half squared misses {Fs - LAM * sum(map(abs, bstar)):.2f} plus charge {LAM * sum(map(abs, bstar)):.2f}")
_, Hb, _ = run(100, 3 * al, 3 * al * LAM, False)
bl, Hl, _ = run(50, al, LAM, False)
bs, Hs, _ = run(K, al, 0.0, False, subgrad=True)
print(f"mistake, step 3/L: log10 F after 100 steps {math.log10(Hb[-1]):.2f}")
print(f"mistake, shrink by lambda not step*lambda: kept {sum(t != 0.0 for t in bl)}, F {Hl[-1]:.2f}")
print(f"mistake, subgradient steps: kept {sum(t != 0.0 for t in bs)}, F - F* after {K} steps {Hs[-1] - Fs:.4f}")
assert eig_res < 1e-6 * L                                   # L is an eigenvalue of A'A
assert all(abs(soft(al * c0[j], al * LAM) - prox_by_search(al * c0[j], al * LAM)) < 1e-7 for j in range(P))
assert abs(gs) < 1e-6 and kkt < 1e-6 and gap_cd < 1e-5      # certificate; two roads agree
assert all(Hi[k] - Fs <= L * d0 / (2 * k) for k in range(1, K + 1))          # ISTA's rate
assert all(Hf[k] - Fs <= 2 * L * d0 / (k + 1) ** 2 for k in range(1, K + 1)) # FISTA's rate
assert all(Hi[k + 1] <= Hi[k] + 1e-9 for k in range(K))     # ISTA never goes uphill
assert Hb[-1] > 1e6 * Hb[0] and Hl[-1] == F([0.0] * P)
print("ALL CHECKS PASS")
