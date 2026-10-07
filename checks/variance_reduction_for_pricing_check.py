# Cheaper Monte Carlo -- the check behind the card.  Standard library only.  Nothing imported
# knows an answer: the fractions come from the recurrence the Monte Carlo pricing card prints,
# the bell-curve area and both reference prices from Simpson's rule written out here in one
# dimension and in two, and the area's inverse is a rational fit the run checks against it.
from math import exp, log, pi, sqrt
S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0     # the house market
T1, T2 = 0.5, 1.0                        # the average ticket's two observation dates
SEED, N, MOD = 20260919, 16000, 1 << 32  # the seed; payoff evaluations per sampler
DISC, MU, EQ = exp(-R * T), R - Q - 0.5 * SIG * SIG, S * exp(-Q * T)   # discount; log drift; S e^-qT
VT, ROT = SIG * sqrt(T), sqrt(0.5)       # a year's wiggle unit; end point back to shocks
A1, A2 = SIG * sqrt(T1), SIG * sqrt(T2 - T1)          # a wiggle unit for each leg
AA = (2.50662823884, -18.61500062529, 41.39119773534, -25.44106049637)
BB = (-8.47351093090, 23.08336743743, -21.06224101826, 3.13082909833)
CC = (0.3374754822726147, 0.9761690190917186, 0.1607979714918209, 0.0276438810333863, 0.0038405729373609,
      0.0003951896511919, 0.0000321767881768, 0.0000002888167364, 0.0000003960315187)
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height at x
def simpson(f, a, b, n):                 # the area under f from a to b, in n slices
    h, total = (b - a) / n, f(a) + f(b)
    for i in range(1, n): total += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return total * h / 3.0
def ncdf(x):                             # area to the left of x, by that same rule
    return 0.0 if x < -9.0 else 1.0 if x > 9.0 else 0.5 + simpson(phi, 0.0, x, 4000)
def ninv(u):                             # the shock with u of the bell curve below it
    y, x = u - 0.5, CC[8]
    if abs(y) < 0.42:                    # the middle: one polynomial in y*y over another
        w = y * y
        top = ((AA[3] * w + AA[2]) * w + AA[1]) * w + AA[0]
        return y * top / ((((BB[3] * w + BB[2]) * w + BB[1]) * w + BB[0]) * w + 1.0)
    w = log(-log(u if y < 0.0 else 1.0 - u))              # the tails: a polynomial in that
    for i in range(7, -1, -1): x = x * w + CC[i]
    return x if y > 0.0 else -x
def nxt(g):   # one step of the recurrence, then a fraction landing strictly inside 0 and 1
    g[0] = (1664525 * g[0] + 1013904223) % MOD; return (g[0] + 0.5) / MOD
def stats(vs):                           # the average, and the error bar on that average
    m, n = sum(vs) / len(vs), len(vs)
    return m, sqrt(sum((v - m) * (v - m) for v in vs) / (n - 1) / n)
def control(xs, ys, known):              # subtract the control's own sampling slip
    n, mx, my = len(xs), sum(xs) / len(xs), sum(ys) / len(ys)
    cov = sum((xs[i] - mx) * (ys[i] - my) for i in range(n)) / (n - 1)
    vx, vy = (sum((x - mx) * (x - mx) for x in xs) / (n - 1), sum((y - my) * (y - my) for y in ys) / (n - 1))
    beta = cov / vy                      # the slope that deletes as much noise as it can
    return (beta, cov / sqrt(vx * vy)) + stats([x - beta * (y - known) for x, y in zip(xs, ys)])

def call(zs):                            # the one-year call, and the share as its control
    end = S * exp(MU * T + VT * zs[0])
    return DISC * max(end - K, 0.0), DISC * end
def asian(zs):                           # one path: the arithmetic ticket, then the geometric
    mid = S * exp(MU * T1 + A1 * zs[0])
    end = mid * exp(MU * (T2 - T1) + A2 * zs[1])
    return DISC * max(0.5 * (mid + end) - K, 0.0), DISC * max(sqrt(mid * end) - K, 0.0), mid, end
def grid2(which, n):                     # either ticket with no pricing formula at all
    return simpson(lambda x: simpson(lambda y: phi(x) * phi(y) * asian((x, y))[which], -8.0, 8.0, n), -8.0, 8.0, n)
def stream(pay, dim, seed):              # N paths: the shocks, the payoff, its control
    g = [seed]
    shocks = [tuple(ninv(nxt(g)) for _ in range(dim)) for _ in range(N)]
    return shocks, [pay(zs)[0] for zs in shocks], [pay(zs)[1] for zs in shocks]
def stratified(pay, seed, mode):         # two draws inside each equal-chance slice
    # mode 0: the only shock.  1: the end point sliced, middle free.  2: leg one sliced, wrong way.
    g, slices, total, spread = [seed], N // 2, 0.0, 0.0
    for j in range(slices):
        vals = []
        for _ in range(2):
            v, w = ninv((j + nxt(g)) / slices), (ninv(nxt(g)) if mode else 0.0)
            vals.append(pay((v,) if mode == 0 else (((v + w) * ROT, (v - w) * ROT) if mode == 1 else (v, w)))[0])
        total += 0.5 * (vals[0] + vals[1])
        spread += 0.25 * (vals[0] - vals[1]) * (vals[0] - vals[1])
    return total / slices, sqrt(spread) / slices
def report(title, pay, shocks, xs, ys, known, exact, mode):
    lows = xs[:N // 2]                   # the same paths, and the same paths flipped
    highs = [pay(tuple(-z for z in zs))[0] for zs in shocks[:N // 2]]
    beta, rho, cv, se_cv = control(xs, ys, known)
    rows = [("plain", stats(xs)), ("antithetic pairs", stats([0.5 * (a + b) for a, b in zip(lows, highs)])),
            ("stratified slices", stratified(pay, SEED, mode)), ("control variate", (cv, se_cv))]
    print(title)
    print("  sampler               estimate    se, c   off by, c   paths worth, millions")
    for name, (mean, se) in rows:
        print(f"  {name:<19}{mean:11.6f} {100.0 * se:8.2f} {100.0 * (mean - exact):11.2f}"
              f"{N * (rows[0][1][1] / se) * (rows[0][1][1] / se) / 1e6:23.3f}")
    mrho = control(lows, highs, 0.0)[1]  # how a path and its mirror move together
    print(f"  mirror correlation {mrho:+.6f}, control slope {beta:.6f}, control correlation {rho:.6f}")
    return rows, stats(lows + highs)[1], mrho, rho

D1 = (log(S / K) + (R - Q + 0.5 * SIG * SIG) * T) / VT
CALL_F = EQ * ncdf(D1) - K * DISC * ncdf(D1 - VT)                # the pilot card's formula
CALL_G = simpson(lambda z: phi(z) * call((z,))[0], (log(K / S) - MU * T) / VT, 9.0, 2000)
VG, TBAR = SIG * SIG * (3.0 * T1 + T2) / 4.0, 0.5 * (T1 + T2)   # the geometric average's log spread
SG, EG = sqrt(VG), S * exp(MU * TBAR + 0.5 * VG)                # its spread; its own average
G2 = (log(S) + MU * TBAR - log(K)) / SG
GEO_F = DISC * (EG * ncdf(G2 + SG) - K * ncdf(G2))              # Kemna and Vorst, 1990
ARI_G, GEO_G = grid2(0, 800), grid2(1, 800)
slip = max(abs(ncdf(ninv(p / 20.0)) - p / 20.0) for p in range(1, 20))
(SHOCKS, XA, YA), (SHOCKS_C, XC, YC) = stream(asian, 2, SEED), stream(call, 1, SEED)
gaps = [XA[i] - YA[i] for i in range(N)]
print("Cheaper Monte Carlo: the Acme call, and an average-price ticket on two dates")
print(f"S = {S:.2f}  K = {K:.2f}  r = {R * 100:.0f}%  q = {Q * 100:.0f}%  sigma = {SIG * 100:.0f}%  "
      f"T = {T:.0f} year; the average takes the price at {T1:.2f} and at {T2:.2f}")
print(f"seed {SEED}; {N} payoff evaluations per sampler: {N // 2} mirror pairs, or {N // 2} slices"
      f" with two draws each; se and off-by in cents")
print()
print("exact prices")
print(f"  Acme call          formula      {CALL_F:11.6f}    one-shock slices  {CALL_G:11.6f}")
print(f"  geometric ticket   Kemna-Vorst  {GEO_F:11.6f}    two-shock grid    {GEO_G:11.6f}")
print(f"  arithmetic ticket  no formula                  two-shock grid    {ARI_G:11.6f}")
print(f"  the geometric average by hand: spread {SG:.6f}, average {EG:.6f}, N(g1) {ncdf(G2 + SG):.6f}, N(g2) {ncdf(G2):.6f}")
print(f"  what the control leaves to sample: {ARI_G:.6f} - {GEO_F:.6f} = {ARI_G - GEO_F:.6f}")
print(f"  the inverse against the area: worst slip over 19 points, in billionths {slip * 1e9:.3f}")
print()
print("the first three paths, and how close the two tickets run")
for i in range(3):
    x, y, mid, end = asian(SHOCKS[i])
    print(f"  path {i + 1}  shocks {SHOCKS[i][0]:9.6f} {SHOCKS[i][1]:9.6f}  prices {mid:9.4f} {end:9.4f}"
          f"  averages {0.5 * (mid + end):9.4f} {sqrt(mid * end):9.4f}  X {x:7.4f}  Y {y:7.4f}  X - Y {x - y:7.4f}")
print(f"  X - Y over {N} paths: average {sum(gaps) / N:.6f}, largest {max(gaps):.6f}, smallest {min(gaps):.6f}")
print()
rows_c, pool_c, mrho_c, _ = report(f"the Acme call, four samplers, exact price {CALL_F:.6f}", call, SHOCKS_C, XC, YC, EQ, CALL_F, 0)
print()
rows_a, _, mrho_a, rho_a = report(f"the arithmetic ticket, four samplers, exact price {ARI_G:.6f}", asian, SHOCKS, XA, YA, GEO_F, ARI_G, 1)
print()
bad, wrong_way = control(XC, YC, S)[2], stratified(asian, SEED, 2)
print("what breaks")
print(f"  mirrors pooled as {N} lone paths: se quoted {100.0 * pool_c:.2f} c, honest {100.0 * rows_c[1][1][1]:.2f} c")
print(f"  control average read as S {S:.2f}, not S e^-qT {EQ:.6f}: the call comes out at {bad:.4f},"
      f" off by {bad - rows_c[3][1][0]:+.4f}")
print(f"  leg one sliced, not the end point: {wrong_way[0]:.4f}, se {100.0 * wrong_way[1]:.2f} c against {100.0 * rows_a[2][1][1]:.2f} c")
print()
print("bar, se in cents on the arithmetic ticket: " + "  ".join(f"{n} {100.0 * r[1]:.2f}" for n, r in rows_a))
pv = [asian((-1.0 + 0.5 * i, -1.0 + 0.5 * i)) for i in range(9)]
for label, vals in (("chart, shock      ", [-1.0 + 0.5 * i for i in range(9)]),
                    ("chart, arithmetic ", [p[0] for p in pv]), ("chart, geometric  ", [p[1] for p in pv])):
    print("  " + label + " ".join(f"{v:8.2f}" for v in vals))
assert abs(CALL_F - 9.227005508154) < 1e-9, "own bell-curve area against the pilot card's price"
assert abs(CALL_G - CALL_F) < 1e-8, "the call by slices against the call by formula"
assert abs(GEO_G - GEO_F) < 1e-4, "the grid reproduces the one ticket price that has a formula"
assert min(gaps) >= 0.0, "a geometric average never beats an arithmetic one"
assert slip < 1e-8, "the inverse really inverts the area"
assert abs(rows_a[3][1][0] - ARI_G) < 2.0 * rows_a[3][1][1], "controlled ticket against the grid price"
assert abs(rows_c[2][1][0] - CALL_F) < 3.0 * rows_c[2][1][1], "sliced call against the formula price"
assert mrho_c < 0.0 and mrho_a < 0.0 and rows_a[1][1][1] < rows_a[0][1][1], "mirrors anti-correlate, so a pair is quieter"
assert abs((rows_a[3][1][1] / rows_a[0][1][1]) ** 2 - (1.0 - rho_a * rho_a)) < 1e-12 and rho_a > 0.999, "the bar falls by exactly 1 - rho^2"
print("ALL CHECKS PASS")
