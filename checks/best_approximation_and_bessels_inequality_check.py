# Best approximation and Bessel's inequality: three harmonics fitted to a tide record.
# Standard library only. Every number on the card is printed here.
from math import pi, cos, sin, sqrt

DAY, M, N = 24.84, 12000, 3          # lunar day (hours), quadrature points, degree of the fit
SURGE, X0, W = 0.40, 1.0, 0.6        # storm surge: peak (m), centre and half-width (radians)
WAVES = ((1, 0.35, 0.9), (2, 1.20, 0.4), (4, 0.15, 0.8))   # (harmonic, amplitude m, phase rad)

def tide(x):                         # illustrative record: height above chart datum, metres
    h = 2.10 + SURGE * max(0.0, 1.0 - abs(x - X0) / W)
    for n, amp, ph in WAVES:
        h += amp * cos(n * x - ph)
    return h

def mean(v): return sum(v) / len(v)  # (1/2pi) times the integral over one cycle
def simpson(v):                      # the same average by Simpson's rule, both ends included: for a window that does not repeat
    m = len(v) - 1; return sum(x * (1 if k in (0, m) else 4 - 2 * (k % 2 == 0)) for k, x in enumerate(v)) / (3 * m)
def grid(m): return [-pi + 2 * pi * k / m for k in range(m)]
def coeffs(xs, hs, deg, avg=mean):   # road 1: [mean, a_1, b_1, ...] by quadrature
    c = [avg(hs)]
    for n in range(1, deg + 1):
        c += [2 * avg([h * cos(n * x) for x, h in zip(xs, hs)]),
              2 * avg([h * sin(n * x) for x, h in zip(xs, hs)])]
    return c
def evaluate(c, x):
    return c[0] + sum(c[2 * n - 1] * cos(n * x) + c[2 * n] * sin(n * x) for n in range(1, len(c) // 2 + 1))
def excess(c, d):                    # sum of |h^(n) - c_n|^2 over |n| <= N, in real form
    return (c[0] - d[0]) ** 2 + sum((c[i] - d[i]) ** 2 for i in range(1, len(c))) / 2

def closed(n):                       # road 2: the coefficients in closed form
    if n == 0: return 2.10 + SURGE * W / (2 * pi), 0.0
    k = (SURGE / pi) * 2 * (1 - cos(n * W)) / (n * n * W)
    a, b = k * cos(n * X0), k * sin(n * X0)
    for nn, amp, ph in WAVES:
        if n == nn: a, b = a + amp * cos(ph), b + amp * sin(ph)
    return a, b

xs = grid(M); hs = [tide(x) for x in xs]
E = mean([h * h for h in hs])        # ||h||^2: mean square height by quadrature
tri = SURGE * W / (2 * pi)           # ||h||^2 in closed form: constant, waves, surge, cross terms
E_closed = 2.10 ** 2 + sum(a * a / 2 for _, a, _ in WAVES) + SURGE * SURGE * W / (3 * pi) + 2 * 2.10 * tri
for n, amp, ph in WAVES:
    k = (SURGE / pi) * 2 * (1 - cos(n * W)) / (n * n * W)
    E_closed += amp * k * cos(n * X0 - ph)
energy = [closed(0)[0] ** 2] + [(a * a + b * b) / 2 for a, b in (closed(n) for n in range(1, 100001))]
bessel, run = [], 0.0
for e in energy:
    run += e; bessel.append(run)     # bessel[N] = sum over |n| <= N of |h^(n)|^2
print(f"record: lunar day {DAY} h, {M} points, surge {SURGE:.2f} m at {(X0 + pi) * DAY / (2 * pi):.2f} h")
print(f"||h||^2 (m^2): quadrature {E:.9f}  closed form {E_closed:.9f}  Parseval to n=100000 {bessel[-1]:.9f}")
c = coeffs(xs, hs, max(N, 4))
print(" n    a_n(m)    b_n(m)  ampl.(m)  closed  energy e_n  Bessel B_n  leftover")
for n in range(5):
    a, b = (c[0], 0.0) if n == 0 else (c[2 * n - 1], c[2 * n])
    amp = abs(a) if n == 0 else sqrt(a * a + b * b)
    ca, cb = closed(n)
    print(f"{n:2d} {a:9.6f} {b:9.6f} {amp:9.6f} {sqrt(ca * ca + cb * cb):7.4f} {energy[n]:11.6f}"
          f" {bessel[n]:11.6f} {E_closed - bessel[n]:9.6f}")
    assert abs(a - ca) < 1e-7 and abs(b - cb) < 1e-7, "quadrature against closed form"
best = c[:2 * N + 1]
left = mean([(h - evaluate(best, x)) ** 2 for x, h in zip(xs, hs)])
print(f"best fit leftover: direct {left:.6f} m^2, E - B_{N} {E - bessel[N]:.6f} m^2, rms {100 * sqrt(left):.2f} cm")

# road 3: least squares by brute force, normal equations solved by elimination
basis = [lambda x: 1.0] + [f for n in range(1, N + 1)
                          for f in (lambda x, n=n: cos(n * x), lambda x, n=n: sin(n * x))]
cols = [[f(x) for x in xs] for f in basis]
G = [[mean([u * v for u, v in zip(ci, cj)]) for cj in cols] + [mean([u * h for u, h in zip(ci, hs)])]
     for ci in cols]
for i in range(len(G)):
    p = max(range(i, len(G)), key=lambda r: abs(G[r][i])); G[i], G[p] = G[p], G[i]
    for r in range(len(G)):
        if r != i:
            f = G[r][i] / G[i][i]; G[r] = [u - f * v for u, v in zip(G[r], G[i])]
ls = [G[i][-1] / G[i][i] for i in range(len(G))]
gap = max(abs(u - v) for u, v in zip(ls, best))
print(f"least squares by elimination: {' '.join(f'{v:.4f}' for v in ls)}; largest gap {gap:.12f}")

table = [2.10, 0.35 * cos(0.9), 0.35 * sin(0.9), 1.20 * cos(0.4), 1.20 * sin(0.4)] + [0.0] * (2 * N - 4)
nodes = grid(7); vals = [tide(x) for x in nodes]
interp = coeffs(nodes, vals, N)      # passes through 7 readings, 3.55 h apart
nudged = best[:]; nudged[3] *= 1.05; nudged[4] *= 1.05
for name, d in (("tide table", table), ("through 7 readings", interp), ("semidiurnal +5%", nudged)):
    direct = mean([(h - evaluate(d, x)) ** 2 for x, h in zip(xs, hs)])
    print(f"{name:<19} leftover {direct:.6f}  Pythagoras {left + excess(best, d):.6f}  rms {100 * sqrt(direct):.2f} cm")
    assert abs(direct - left - excess(best, d)) < 1e-9, "Pythagoras for the rival"
    assert direct > left, "the partial sum beats the rival"
s, lows = 20261115, []               # SplitMix64, seed 20261115: random rivals
def rnd():
    global s
    s = (s + 0x9E3779B97F4A7C15) & (2 ** 64 - 1); z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
coarse = grid(1200); hc = [tide(x) for x in coarse]; lc = mean([(h - evaluate(best, x)) ** 2 for x, h in zip(coarse, hc)])
for _ in range(200):
    d = [v + 0.05 * (2 * rnd() - 1) for v in best]
    lows.append(mean([(h - evaluate(d, x)) ** 2 for x, h in zip(coarse, hc)]))
print(f"200 random rivals within 5 cm: best of them {min(lows):.6f}, fit {lc:.6f} (coarse grid)")
assert min(lows) > lc, "no rival beats the partial sum"
miss = max(range(M), key=lambda k: abs(hs[k] - evaluate(best, xs[k])))
print(f"largest miss {100 * (hs[miss] - evaluate(best, xs[miss])):.1f} cm at {(xs[miss] + pi) * DAY / (2 * pi):.2f} h;"
      f" at the surge peak record {tide(X0):.3f} m, fit {evaluate(best, X0):.3f} m")
u1 = [sqrt(2) * cos(x) for x in xs]; u2 = [sqrt(2) * cos(x - 0.5) for x in xs]
skew = mean([u * u for u in u1]) ** 2 + mean([u * v for u, v in zip(u1, u2)]) ** 2
print(f"breaks: skewed pair cos x, cos(x - 0.5): 'Bessel sum' {skew:.4f} against energy {mean([u * u for u in u1]):.4f}")
assert skew > 1.5, "Bessel needs an orthonormal family"
l24 = []                             # a 24.00 h window does not repeat: Simpson's rule at two cut-offs
for m24 in (M // 2, M):
    x24 = [-pi + 2 * pi * (24.0 * k / m24) / DAY for k in range(m24 + 1)]; h24 = [tide(x) for x in x24]
    c24 = coeffs([-pi + 2 * pi * k / m24 for k in range(m24 + 1)], h24, N, simpson)
    l24.append(simpson([h * h for h in h24]) - excess(c24, [0.0] * (2 * N + 1)))
    print(f"breaks: 24.00 h window, {m24} cells, leftover {l24[-1]:.6f} m^2 (rms {100 * sqrt(l24[-1]):.2f} cm), semidiurnal {sqrt(c24[3] ** 2 + c24[4] ** 2):.4f} m")
assert abs(l24[0] - l24[1]) < 1e-8 and l24[1] > left, "the 24 h leftover has settled, and is worse than a lunar day's"
for n in (10, 100, 1000):
    bound = sqrt(2 * (E_closed - bessel[n - 1]))
    print(f"n = {n:4d}: amplitude {2000 * sqrt(energy[n] / 2):.6f} mm, Bessel bound {1000 * bound:.6f} mm, left after n {E_closed - bessel[n]:.12f}")
    assert energy[n] <= E_closed - bessel[n - 1], "Bessel caps each later coefficient"
even = sum(energy[n] for n in range(0, 100001, 2))
print(f"even harmonics only: Bessel sum {even:.6f} < {E_closed:.6f}; gap {E_closed - even:.6f} m^2")
print("chart hours  " + " ".join(f"{t:5d}" for t in range(25)))
for name, f in (("chart record", tide), ("chart fit   ", lambda x: evaluate(best, x))):
    print(name + " " + " ".join(f"{f(-pi + 2 * pi * t / DAY):5.2f}" for t in range(25)))
assert abs(E - E_closed) < 1e-7, "quadrature against closed form for ||h||^2"
assert abs(bessel[-1] - E_closed) < 1e-10, "Parseval sum against closed form for ||h||^2"
assert abs(left - (E - bessel[N])) < 1e-7, "leftover equals energy minus Bessel sum"
assert gap < 1e-9, "brute-force least squares lands on the Fourier coefficients"
print("ALL CHECKS PASS")
