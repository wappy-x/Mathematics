# Autoregression, AR(1) and AR(2) -- the check behind the card.  Standard library
# only: math supplies sqrt, log, cos and exp.  Every random draw comes from
# SplitMix64 (seed 2026) and Box-Muller, written out here, so Python and Rust
# draw the same numbers.  Model station: X_t = 0.1 + 0.8 X_(t-1) + shock, sd 1.2.
import math

PHI, C, SIG, N = 0.8, 0.1, 1.2, 365
MU, VAR = C / (1 - PHI), SIG**2 / (1 - PHI**2)
SD, X_NOW, HS, YEARS, PATHS = math.sqrt(VAR), 4.5, [1, 2, 3, 5, 10], 2000, 20000
MASK, state = (1 << 64) - 1, 2026

def u01():                                   # SplitMix64, mapped into (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0**53

def gauss():                                 # Box-Muller: one standard normal draw
    u1, u2 = u01(), u01()
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)

def cdf(x):                                  # Phi(x): 1/2 plus a Simpson integral
    n, h = 2000, x / 2000
    s = sum((1 if i in (0, n) else 4 if i % 2 else 2) * math.exp(-(i * h)**2 / 2)
            for i in range(n + 1))
    return 0.5 + s * h / 3 / math.sqrt(2 * math.pi)

def year():                                  # day 0 from the stationary law, then 365 days
    x, eps = [MU + SD * gauss()], []
    for _ in range(N):
        eps.append(SIG * gauss())
        x.append(C + PHI * x[-1] + eps[-1])
    return x[1:], eps

def ls_ar1(x):                               # road one: least squares, today on yesterday
    a, b = x[:-1], x[1:]
    ma, mb = sum(a) / len(a), sum(b) / len(b)
    sxx = sum((u - ma)**2 for u in a)
    slope = sum((u - ma) * (v - mb) for u, v in zip(a, b)) / sxx
    icpt = mb - slope * ma
    s2 = sum((v - icpt - slope * u)**2 for u, v in zip(a, b)) / (len(a) - 2)
    return slope, icpt, math.sqrt(s2), math.sqrt(s2 / sxx)

def acf(x, k):                               # road two: sample autocorrelations 0..k
    m = sum(x) / len(x)
    g = [sum((x[t] - m) * (x[t - h] - m) for t in range(h, len(x))) / len(x)
         for h in range(k + 1)]
    return m, g[0], [gh / g[0] for gh in g]
def top_root(p1, p2):                        # largest |lambda| with lambda^2 = p1 lambda + p2
    d = p1 * p1 + 4 * p2
    return (abs(p1) + math.sqrt(d)) / 2 if d >= 0 else math.sqrt(-p2)
def triangle(p1, p2):                        # the AR(2) stationarity triangle
    return p1 + p2 < 1 and p2 - p1 < 1 and abs(p2) < 1
def row(label, vals, fmt="{:.2f}"):
    print(f"{label:<36}" + " ".join(fmt.format(v) for v in vals))

lo, hi = 0.0, 5.0                            # the 95% point: bisect Phi(z) = 0.975
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if cdf(mid) < 0.975 else (lo, mid)
Z95 = (lo + hi) / 2
tail = SIG**2 * sum(PHI**(2 * j) for j in range(200))
row("model phi, c, sigma, z95", [PHI, C, SIG, Z95], "{:.6f}")
row("mean c/(1-phi), var, sd", [MU, VAR, SD], "{:.4f}")
row("variance, 200 weights summed", [tail], "{:.4f}")
row("hand: 1-phi,phi^2,1-phi^2,sig^2,gap", [1 - PHI, PHI**2, 1 - PHI**2, SIG**2, X_NOW - MU], "{:.4f}")
row("hand: phi^h x gap h=1,2,10; phi^10", [PHI * 4, PHI**2 * 4, PHI**10 * 4, PHI**10], "{:.4f}")
row("hand: 1+phi^2, var h=2", [1 + PHI**2, SIG**2 * (1 + PHI**2)], "{:.4f}")
x, eps = year()
row("chart, AR(1) days 1-15", x[0:15]); row("chart, AR(1) days 16-30", x[15:30])
row("chart, shocks alone days 1-15", [MU + e for e in eps[0:15]]); row("chart, shocks alone days 16-30", [MU + e for e in eps[15:30]])
b, a, s, se = ls_ar1(x)
m, g0, r = acf(x, 5)
row("LS fit phi, c, sigma, se(phi)", [b, a, s, se], "{:.4f}")
row("YW fit phi = r1, c = m(1-r1)", [r[1], m * (1 - r[1])], "{:.4f}")
row("se formula sqrt((1-phi^2)/n)", [math.sqrt((1 - PHI**2) / N)], "{:.4f}")
row("record mean, variance, se(mean)", [m, g0, SIG / (1 - PHI) / math.sqrt(N)], "{:.4f}")
row("acf lags 1-5, record", r[1:], "{:.3f}"); row("acf lags 1-5, phi^h", [PHI**h for h in range(1, 6)], "{:.3f}")
y = [v - m for v in x]
def S(i, j): return sum(y[t - i] * y[t - j] for t in range(2, N))
s11, s12, s22, s01, s02 = S(1, 1), S(1, 2), S(2, 2), S(0, 1), S(0, 2)
det = s11 * s22 - s12**2
p1, p2 = (s01 * s22 - s02 * s12) / det, (s02 * s11 - s01 * s12) / det
res = sum((y[t] - p1 * y[t - 1] - p2 * y[t - 2])**2 for t in range(2, N)) / (N - 5)
se2 = math.sqrt(res * s11 / det)
q1, q2 = r[1] * (1 - r[2]) / (1 - r[1]**2), (r[2] - r[1]**2) / (1 - r[1]**2)
row("AR(2) LS phi1, phi2, se(phi2)", [p1, p2, se2], "{:.4f}")
row("AR(2) YW phi1, phi2", [q1, q2], "{:.4f}")
h1, h2 = round(r[1], 3), round(r[2], 3)      # Step 6 by hand, from the three-place r(1), r(2)
row("hand: AR(2) YW 3dp; 1-r1^2; 2/sqrtn", [h1 * (1 - h2) / (1 - h1**2), (h2 - h1**2) / (1 - h1**2), 1 - h1**2, SD / math.sqrt(N)], "{:.4f}")
print(f"{'AR(2) fit: top |root|, in triangle':<36}{top_root(p1, p2):.4f} {'yes' if triangle(p1, p2) else 'no'}")
fits, ends = [], []
for _ in range(YEARS):                       # road three: 2000 simulated years
    xs, es = year()
    fits.append(ls_ar1(xs)[0])
    ends.append(sum(es))                     # a random walk fed the same shocks
mf = sum(fits) / YEARS
sf = math.sqrt(sum((f - mf)**2 for f in fits) / (YEARS - 1))
se_ = math.sqrt(sum(e * e for e in ends) / YEARS)
row("2000 years: mean phi_hat, sd", [mf, sf], "{:.4f}")
row("theory: phi-(1+3phi)/n, se", [PHI - (1 + 3 * PHI) / N, math.sqrt((1 - PHI**2) / N)], "{:.4f}")
row("random walk sd day 365: sim, rule", [se_, math.sqrt(N) * SIG], "{:.2f}")
got = {h: [] for h in HS}
for _ in range(PATHS):                       # forecast paths from +4.5 today
    v = X_NOW
    for h in range(1, 11):
        v = C + PHI * v + SIG * gauss()
        if h in got: got[h].append(v)
fm = lambda h: MU + PHI**h * (X_NOW - MU)
fs = lambda h: SIG * math.sqrt((1 - PHI**(2 * h)) / (1 - PHI**2))
print("h   mean    sd      lower   upper  | sim mean  sim sd  inside band")
checks = []
for h in HS:
    g = got[h]; mm = sum(g) / PATHS; ss = math.sqrt(sum((v - mm)**2 for v in g) / (PATHS - 1))
    cov = sum(abs(v - fm(h)) <= Z95 * fs(h) for v in g) / PATHS
    checks.append((h, mm, ss, cov))
    print(f"{h:<3} {fm(h):<7.3f} {fs(h):<7.3f} {fm(h) - Z95 * fs(h):<7.3f} {fm(h) + Z95 * fs(h):<6.3f} "
          f"| {mm:<9.3f} {ss:<7.3f} {cov:.4f}")
row("chart, forecast h 0-10", [fm(h) for h in range(11)])
row("chart, lower 95% h 0-10", [fm(h) - Z95 * fs(h) for h in range(11)])
row("chart, upper 95% h 0-10", [fm(h) + Z95 * fs(h) for h in range(11)])
psi = [1.0, 0.5]                             # a shock's echo in AR(2) with 0.5 and 0.6
for j in range(2, 51): psi.append(0.5 * psi[-1] + 0.6 * psi[-2])
row("wrong: 0.5,0.6 root, ratio, echo 50", [top_root(0.5, 0.6), psi[50] / psi[49], psi[50]], "{:.4f}")
row("wrong: 30-day forecast toward c", [C, fm(30)], "{:.4f}")
row("wrong: h=1 half-band stationary sd", [Z95 * SD, Z95 * fs(1)], "{:.4f}")
assert abs(b - r[1]) < 0.02 and abs(q2 - p2) < 0.02    # two estimators, one record
assert abs(b - PHI) < 4 * se and abs(tail - VAR) < 1e-9
assert abs(s - SIG) < 4 * SIG / math.sqrt(2 * (N - 1))     # residual spread recovers the shock's 1.2
assert abs(mf - (PHI - (1 + 3 * PHI) / N)) < 4 * sf / math.sqrt(YEARS)
assert abs(se_ - math.sqrt(N) * SIG) < 4 * math.sqrt(N) * SIG / math.sqrt(2 * YEARS)
for h, mm, ss, cov in checks:
    assert abs(mm - fm(h)) < 4 * fs(h) / math.sqrt(PATHS)
    assert abs(ss - fs(h)) < 4 * fs(h) / math.sqrt(2 * PATHS)
    assert abs(cov - 0.95) < 4 * math.sqrt(0.95 * 0.05 / PATHS)
assert abs(Z95 - 1.959964) < 1e-6 and abs(psi[50] / psi[49] - top_root(0.5, 0.6)) < 1e-6
assert triangle(p1, p2) == (top_root(p1, p2) < 1) and triangle(0.5, 0.6) == (top_root(0.5, 0.6) < 1)
print("ALL CHECKS PASS")
