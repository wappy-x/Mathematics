# Markov, Chebyshev and Chernoff on the river: the check behind the card.
# Standard library only. Fraction for exact moments; own integrator, series, minimiser and RNG.
import math
from fractions import Fraction as F

def d(x): return 4 * x * (1 - x)                 # depth in metres at x km along the stretch
def f6(v): return f"{float(v):.6f}"
def poly_int(c): return sum(F(ck, k + 1) for k, ck in enumerate(c))   # integral over [0, 1] of sum c_k x^k

# road 1: exact moments and exact tails
m = poly_int([0, 4, -4]); m2 = poly_int([0, 0, 16, -32, 16]); var = m2 - m * m
def tail_up(a): return math.sqrt(1 - a)          # length of {d >= a}: roots (1 -+ sqrt(1 - a)) / 2
def tail_low(b): return 1 - math.sqrt(1 - b)     # length of {d <= b}
a, eps = F(9, 10), F(1, 2)
mk, ch = m / a, var / eps**2
t_mk, t_ch = tail_up(0.9), tail_low(1 / 6)

# road 2: the Lebesgue view on a grid of N cells, sizes of level sets counted directly
N = 1_000_000
gs1 = gs2 = 0.0; g_up = g_ch = 0
for i in range(N):
    y = d((i + 0.5) / N); gs1 += y; gs2 += y * y
    g_up += y >= 0.9; g_ch += abs(y - 2 / 3) >= 0.5
gm, gv = gs1 / N, gs2 / N - (gs1 / N) ** 2

# road 3: a boat moored at 200000 random points, SplitMix64 with seed 20260929
S, MASK = 20260929, (1 << 64) - 1
def rnd():
    global S
    S = (S + 0x9E3779B97F4A7C15) & MASK; z = S
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 2.0**53
R = 200_000; r1 = r2 = 0.0; r_up = r_ch = 0
for _ in range(R):
    y = d(rnd()); r1 += y; r2 += y * y; r_up += y >= 0.9; r_ch += abs(y - 2 / 3) >= 0.5
rm, rv = r1 / R, r2 / R - (r1 / R) ** 2

print("depth d(x) = 4x(1 - x) m, x km uniform on [0, 1]; exact, grid of 10^6 cells, 200000 moorings")
print("mean depth:", f6(m), f6(gm), f6(rm))
print("variance:  ", f6(var), f6(gv), f6(rv), "  (exact 4/45)")
print("P(d >= 0.9):          ", f6(t_mk), f6(g_up / N), f6(r_up / R), "  Markov bound", f6(mk))
print("P(|d - 2/3| >= 0.5):  ", f6(t_ch), f6(g_ch / N), f6(r_ch / R), "  Chebyshev bound", f6(ch))
assert m == F(2, 3) and var == F(4, 45)
assert abs(gm - m) < 1e-9 and abs(gv - var) < 1e-9
assert abs(g_up / N - t_mk) < 2 / N and abs(g_ch / N - t_ch) < 2 / N
for p, c in ((t_mk, r_up), (t_ch, r_ch)): assert abs(c / R - p) < 4 * math.sqrt(p * (1 - p) / R)
assert t_mk < mk and t_ch < ch

# Chernoff: M(t) = integral of e^(t d) by Simpson, and by the series sum (4t)^k k!/(2k+1)!
def M_simpson(t, n=2000):
    h, s = 1 / n, 0.0
    for i in range(n + 1): s += (1 if i in (0, n) else 4 if i % 2 else 2) * math.exp(t * d(i * h))
    return h / 3 * s
def M_series(t):
    s, term, k = 0.0, 1.0, 0
    while k < 12 or abs(term) > 1e-17:
        s += term; k += 1; term *= 4 * t * k / ((2 * k) * (2 * k + 1))
    return s
def argmin(f, lo, hi):                            # golden-section search on a convex function
    g = (math.sqrt(5) - 1) / 2
    for _ in range(120):
        c, e = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(c) < f(e): hi = e
        else: lo = c
    return (lo + hi) / 2
def chernoff_up(a):
    t = argmin(lambda t: math.log(M_simpson(t)) - a * t, 0, 40)
    return t, math.exp(-a * t) * M_simpson(t), math.exp(-a * t) * M_series(t)
t9, c9, c9s = chernoff_up(0.9)
print(f"Chernoff, P(d >= 0.9): best t {t9:.3f}, bound by Simpson {f6(c9)}, by series {f6(c9s)}")
assert abs(c9 - c9s) < 1e-9 and t_mk < c9 < mk
mom = [4**p * math.factorial(p)**2 / math.factorial(2 * p + 1) / 0.9**p for p in range(1, 9)]
print("moment bounds E[d^p]/0.9^p, p = 1..8:", " ".join(f"{v:.4f}" for v in mom))
assert min(mom) < c9 and abs(mom[0] - mk) < 1e-12
tl = argmin(lambda t: math.log(M_simpson(-t)) + t / 6, 0, 40)
cl = math.exp(tl / 6) * M_simpson(-tl)
print(f"P(d <= 1/6): true {f6(tail_low(1 / 6))}; Markov on 1 - d {f6((1 - m) / F(5, 6))};",
      f"Chebyshev {f6(ch)}; Chernoff (t = {tl:.3f}) {f6(cl)}")
assert tail_low(1 / 6) < cl < ch < (1 - m) / F(5, 6)

print("threshold a, true P(d >= a), Markov, Chernoff")
rows = []
for k in range(14, 20):
    x = k / 20; _, c, _ = chernoff_up(x); rows.append((tail_up(x), float(m) / x, c))
    print(f"  {x:.2f}, {f6(rows[-1][0])}, {f6(rows[-1][1])}, {f6(c)}")
    assert rows[-1][0] < min(rows[-1][1:])
for j, name in enumerate(("true", "Markov", "Chernoff")):
    print(f"chart, {name}:", " ".join(f"{r[j]:.2f}" for r in rows))

# tight laws: exact step functions on [0, 1] whose tails meet the bounds
pieces = [(a, F(20, 27)), (F(0), F(7, 27))]      # (depth, length): 0.9 m on [0, 20/27), dry after
ti = sum(h * l for h, l in pieces); tl9 = sum(l for h, l in pieces if h >= a)
print("tight Markov: 0.9 m on 20/27 km, dry after: integral", f6(ti), "tail", f6(tl9), "bound", f6(ti / a))
w = [F(8, 45), F(29, 45), F(8, 45)]; v = [F(1, 6), F(2, 3), F(7, 6)]
tm = sum(p * x for p, x in zip(w, v)); tv = sum(p * (x - tm)**2 for p, x in zip(w, v))
tt = sum(p for p, x in zip(w, v) if abs(x - tm) >= eps)
tstrict = sum(p for p, x in zip(w, v) if abs(x - tm) > eps)
print("tight Chebyshev: 1/6, 2/3, 7/6 m on 8/45, 29/45, 8/45 km: mean", f6(tm), "variance", f6(tv),
      "tail", f6(tt), "bound", f6(tv / eps**2), "strict tail", f6(tstrict))
assert ti == m and tl9 == mk and tm == m and tv == var and tt == ch

print("breaks: Markov on signed d - 2/3 at 0.2 gives", f6((m - F(2, 3)) / F(1, 5)), "against the true", f6(tail_up(13 / 15)))
print("breaks: variance over eps, not eps^2, on the tight law:", f6(tv / eps), "below its tail", f6(tt))
print("breaks: Markov on d itself for P(d <= 1/6):", f6(m / F(1, 6)))
assert tail_up(13 / 15) > (m - F(2, 3)) / F(1, 5) and tv / eps < tt
x1, x2 = (1 - tail_up(0.9)) / 2, (1 + tail_up(0.9)) / 2
print(f"figure, X = 36 + 300x, Y = 210 - 150d; set ends x = {x1:.4f}, {x2:.4f} km, X = {36 + 300 * x1:.2f}, {36 + 300 * x2:.2f};",
      f"Y(0.9) = {210 - 150 * 0.9:.2f}, Y(2/3) = {210 - 100:.2f}; rectangle area {0.9 * tail_up(0.9):.6f}")
