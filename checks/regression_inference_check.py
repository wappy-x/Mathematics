# Regression error bars -- the check behind the card.  Standard library only; nothing imported
# holds the answer.  A cafe logged midday temperature and iced coffees sold on ten summer days.
# Roads: the slope's standard error from deviations and from the 2x2 matrix inverse; t from the
# slope and F from dropping the slope; t tail areas from a finite series and from Simpson's rule;
# a seeded simulation (SplitMix64, Box-Muller) that refits thousands of cafes and counts coverage.
from math import sqrt, atan, sin, cos, log, pi

X = [16, 18, 20, 22, 24, 26, 28, 30, 32, 34]          # midday temperature, degrees C
Y = [37, 33, 34, 31, 35, 49, 40, 53, 50, 38]          # iced coffees sold
N, NU, X0 = len(X), len(X) - 2, 30                     # ten days, 8 degrees of freedom, a 30 C day

def fit(x, y):                                         # least squares from deviations
    n = len(x); mx, my = sum(x) / n, sum(y) / n
    sxx = sum((a - mx) ** 2 for a in x); sxy = sum((a - mx) * b for a, b in zip(x, y))
    b1 = sxy / sxx; b0 = my - b1 * mx
    sse = sum((b - b0 - b1 * a) ** 2 for a, b in zip(x, y))
    return b0, b1, sse, sxx, mx

def t_inside(t, v):                                    # P(|T| <= t), even v: finite series in the angle
    th = atan(t / sqrt(v)); c, term, tot = cos(th) ** 2, 1.0, 1.0
    for k in range(1, v // 2):
        term *= c * (2 * k - 1) / (2 * k); tot += term
    return sin(th) * tot

def simpson(f, a, b, m=2000):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, m)))

def t_dens(t, v=8):                                    # Gamma(9/2) / (sqrt(8 pi) Gamma(4)), Gammas by hand
    g = 3.5 * 2.5 * 1.5 * 0.5 * sqrt(pi) / (sqrt(v * pi) * 6.0)
    return g * (1 + t * t / v) ** (-(v + 1) / 2)

def z_dens(z): return 2.718281828459045 ** (-z * z / 2) / sqrt(2 * pi)

def bisect(f, target, lo, hi):
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(mid) < target else (lo, mid)
    return (lo + hi) / 2

b0, b1, sse, sxx, mx = fit(X, Y)
s = sqrt(sse / NU); se1 = s / sqrt(sxx); se0 = s * sqrt(1 / N + mx ** 2 / sxx)
sx, sxx_raw = sum(X), sum(a * a for a in X)            # road 2: (X'X)^-1 from raw sums, no deviations
g22 = N / (N * sxx_raw - sx * sx); g11 = sxx_raw / (N * sxx_raw - sx * sx); g12 = -sx / (N * sxx_raw - sx * sx)
t = b1 / se1
syy = sum((b - sum(Y) / N) ** 2 for b in Y)            # road 2 for t: the flat line's SSE against the fitted one
F = (syy - sse) / (sse / NU)
tq = bisect(lambda q: t_inside(q, NU), 0.95, 0.0, 20.0)
p_ser, p_simp = 1 - t_inside(t, NU), 1 - 2 * simpson(t_dens, 0.0, t)
h = 1 / N + (X0 - mx) ** 2 / sxx; h_mat = g11 + 2 * X0 * g12 + X0 * X0 * g22
yhat0, hw_m, hw_p = b0 + b1 * X0, tq * s * sqrt(h), tq * s * sqrt(1 + h)
print("data, temperature C  " + " ".join(f"{a:>3}" for a in X))
print("data, iced coffees   " + " ".join(f"{b:>3}" for b in Y))
print(f"sums: mean x {mx:.4f}, mean y {sum(Y) / N:.4f}, Sxx {sxx:.4f}, Sxy {b1 * sxx:.4f}, Syy {syy:.4f}")
print(f"fit: slope {b1:.4f} coffees per degree, intercept {b0:.4f}")
print("residuals " + " ".join(f"{b - b0 - b1 * a:.1f}" for a, b in zip(X, Y)))
print(f"SSE {sse:.4f}; s^2 = SSE/8 {s * s:.4f}; s {s:.4f}")
print(f"hand: sqrt(Sxx) {sqrt(sxx):.4f}; weights at 16 and 34 C {(16 - mx) / sxx:.4f} {(34 - mx) / sxx:.4f}; h at 0 C {1 / N + mx ** 2 / sxx:.4f}")
print(f"road 1, SE(slope) = s/sqrt(Sxx)        {se1:.4f}")
print(f"road 2, SE(slope) = s sqrt(G22)        {s * sqrt(g22):.4f}")
print(f"SE(intercept) {se0:.4f}; road 2 {s * sqrt(g11):.4f}")
print(f"road 1, t = slope / SE                 {t:.4f}; t^2 {t * t:.4f}")
print(f"road 2, F = (Syy - SSE) / s^2          {F:.4f}; Syy - SSE {syy - sse:.4f}")
print(f"cutoff t* for 95%, 8 df                {tq:.4f}; Simpson area outside it {1 - 2 * simpson(t_dens, 0.0, tq):.4f}")
print(f"p-value, t on 8 df: series {p_ser:.4f}; Simpson {p_simp:.4f}")
print(f"95% interval for the slope: {b1 - tq * se1:.4f} to {b1 + tq * se1:.4f} (half-width {tq * se1:.4f})")
print(f"at 30 C: fitted {yhat0:.4f}; h {h:.4f}; h from the matrix {h_mat:.4f}")
print(f"mean sales at 30 C: {yhat0 - hw_m:.2f} to {yhat0 + hw_m:.2f} (SE {s * sqrt(h):.4f}, half-width {hw_m:.2f})")
print(f"one new 30 C day:   {yhat0 - hw_p:.2f} to {yhat0 + hw_p:.2f} (SE {s * sqrt(1 + h):.4f}, half-width {hw_p:.2f})")
p_z = 1 - 2 * simpson(z_dens, 0.0, t); s_n = sqrt(sse / N)
print(f"mistake, normal cutoff: p {p_z:.4f}; true false-alarm rate of 1.96 on 8 df {1 - t_inside(1.96, NU):.4f}")
print(f"mistake, SSE/n: s {s_n:.4f}, SE {s_n / sqrt(sxx):.4f}, t {b1 / (s_n / sqrt(sxx)):.4f}, p {1 - t_inside(b1 / (s_n / sqrt(sxx)), NU):.4f}")
cov_mix = t_inside(tq * sqrt(h / (1 + h)), NU)
print(f"mistake, mean interval for one new day: closed-form coverage {cov_mix:.4f}")

state = 20260928                                      # SplitMix64, the same stream in Python and Rust
def u01():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
def gauss():                                          # Box-Muller, one draw per call
    u = u01()
    while u == 0.0: u = u01()
    return sqrt(-2 * log(u)) * cos(2 * pi * u01())

def cafes(slope, rho, m=20000):                       # refit m simulated cafes; errors AR(1) with rho
    hits = [0] * 5; sb = sb2 = ss2 = 0.0
    for _ in range(m):
        e = s * gauss(); errs = [e]
        for _ in range(N - 1):
            e = rho * e + s * sqrt(1 - rho * rho) * gauss(); errs.append(e)
        y = [b0 + slope * a + ea for a, ea in zip(X, errs)]
        c0, c1, cse, _, _ = fit(X, y); cs = sqrt(cse / NU); cse1 = cs / sqrt(sxx)
        new = b0 + slope * X0 + s * gauss(); mid = c0 + c1 * X0
        sb += c1; sb2 += c1 * c1; ss2 += cs * cs
        hits[0] += abs(c1 - slope) <= tq * cse1; hits[1] += abs(c1 - slope) <= 1.96 * cse1
        hits[2] += abs(mid - (b0 + slope * X0)) <= tq * cs * sqrt(h)
        hits[3] += abs(mid - new) <= tq * cs * sqrt(1 + h); hits[4] += abs(mid - new) <= tq * cs * sqrt(h)
    return [k / m for k in hits], sqrt(sb2 / m - (sb / m) ** 2), ss2 / m, m

rates, sd1, ms2, m = cafes(b1, 0.0)
e = lambda r: sqrt(r * (1 - r) / m)
print(f"simulation, {m} cafes, seed 20260928, true slope 0.8, s as sigma:")
print(f"  spread of fitted slopes {sd1:.4f} (+/- {sd1 / sqrt(2 * m):.4f}); formula sigma/sqrt(Sxx) {s / sqrt(sxx):.4f}")
print(f"  average s^2 {ms2:.4f} (+/- {s * s * sqrt(2 / NU / m):.4f}); true sigma^2 {s * s:.4f}; average SSE/n {ms2 * NU / N:.4f}")
names = ["t interval holds the slope", "1.96 interval holds the slope", "mean interval holds the mean",
         "prediction interval holds the new day", "mean interval holds the new day"]
for nm, r in zip(names, rates): print(f"  {nm:<38}{r:.4f} (+/- {e(r):.4f})")
bad, _, _, _ = cafes(0.0, 0.8)
print(f"drop independence: rho 0.8 day to day, true slope 0; t test rejects {1 - bad[0]:.4f} (+/- {e(bad[0]):.4f}) of cafes")
px = lambda a: 40 + 15 * (a - 15); py = lambda v: 200 - 3 * (v - 10)
grid = list(range(16, 35, 2)); band = lambda a, one: tq * s * sqrt(one + 1 / N + (a - mx) ** 2 / sxx)
print("figure, points " + " ".join(f"{px(a):.1f},{py(b):.1f}" for a, b in zip(X, Y)))
print(f"figure, fit line {px(16):.1f},{py(b0 + b1 * 16):.1f} {px(34):.1f},{py(b0 + b1 * 34):.1f}")
for lab, one, sg in (("mean band upper", 0, 1), ("mean band lower", 0, -1), ("prediction upper", 1, 1), ("prediction lower", 1, -1)):
    print(f"figure, {lab} " + " ".join(f"{px(a):.1f},{py(b0 + b1 * a + sg * band(a, one)):.1f}" for a in grid))
assert abs(t * t - F) < 1e-9 and abs(s * sqrt(g22) - se1) < 1e-12   # two roads to t, two to the SE
assert abs(p_ser - p_simp) < 1e-8 and abs(h - h_mat) < 1e-12        # series against Simpson; h two ways
assert abs(b1 - 0.8) < 1e-12 and abs(sse - 342.8) < 1e-9            # the hand table's numbers
assert abs(sd1 - s / sqrt(sxx)) < 4 * sd1 / sqrt(2 * m) and abs(ms2 - s * s) < 4 * s * s * sqrt(2 / NU / m)
for r, want in zip(rates, [0.95, t_inside(1.96, NU), 0.95, 0.95, cov_mix]): assert abs(r - want) < 4 * e(want)
assert 1 - bad[0] > 0.05 + 4 * e(0.05)                              # dependence breaks the 5 percent
print("ALL CHECKS PASS")
