# Choosing the step -- the check behind the card.  Python standard library only.
# Road 1: exact derivatives of the bond price, as float sums and exact fractions.
# Road 2: difference quotients at many steps over 201 yields; the best found by search.
# Road 3: the best step predicted from the measured noise and the error law.
from fractions import Fraction
from math import sqrt, log10, sin, pi, floor

def price(y):                       # 30-year bond, 5% annual coupon, $100 face
    d = 1.0 / (1.0 + y); df = 1.0; s = 0.0
    for t in range(1, 31):
        df *= d; s += 5.0 * df
    return s + 100.0 * df

def deriv(y, k):                    # k-th derivative in closed form, as a float sum
    d = 1.0 / (1.0 + y); s = 0.0
    for t in range(1, 31):
        r = 1.0; dp = 1.0
        for j in range(k): r *= -(t + j)
        for j in range(t + k): dp *= d
        s += (5.0 if t < 30 else 105.0) * r * dp
    return s

def exact(y, k):                    # the same sum in exact fractions (Python only)
    d = 1 / (1 + Fraction(y)); s = Fraction(0)
    for t in range(1, 31):
        r = 1
        for j in range(k): r *= -(t + j)
        s += (5 if t < 30 else 105) * r * d ** (t + k)
    return s

def cbrt(a):                        # cube root by Newton's method, + - * / only
    r = 1.0
    for _ in range(200): r = (2.0 * r + a / (r * r)) / 3.0
    return r

def root(a, n): return sqrt(a) if n == 2 else (cbrt(a) if n == 3 else sqrt(sqrt(a)))

def pow2(h):                        # nearest power of two: an exactly stored step
    p = 1.0
    while p > h: p /= 2.0
    while p * 2.0 <= h: p *= 2.0
    return p * 2.0 if h / p > sqrt(2.0) else p

def fwd(f, x, h): return (f(x + h) - f(x)) / h
def cen(f, x, h): return (f(x + h) - f(x - h)) / (2.0 * h)
def sec(f, x, h): return (f(x + h) - 2.0 * f(x) + f(x - h)) / (h * h)
def E(v, d=2):
    m, e = f"{v:.{d}e}".split("e"); return f"{m}e{int(e)}"
def rel(v, t): return abs(v - t) / abs(t)

eps = 2.0 ** -52
x = 0.05
bp = lambda b: price(b / 1e4)        # the same bond, yield kept in basis points
D = [deriv(x, k) for k in range(5)]
for k in range(5): assert rel(D[k], float(exact(x, k))) < 1e-13
assert abs(D[0] - 100.0) < 1e-12        # coupon = yield: a par bond is worth its face
c = cbrt(eps); assert rel(c * c * c, eps) < 1e-15   # the cube root cubes back
print(f"house: 30-year bond, 5% coupon, yield 0.05, price {D[0]:.9f}")
print(f"eps_mach = {E(eps)}; its roots 1/2, 1/3, 1/4: {E(sqrt(eps))}, {E(c)}, {E(sqrt(sqrt(eps)))}")
print(f"exact: P' = {D[1]:.9f} ({D[1] / 1e4:.6f} per bp), P'' = {D[2]:.7f}")
print(f"exact: P''' = {D[3]:.6f}, P'''' = {D[4]:.4f}")

vals = [price(x + i * 1e-12) for i in range(400)]   # noise from 4th differences
for _ in range(4): vals = [vals[i + 1] - vals[i] for i in range(len(vals) - 1)]
eta = sqrt(sum(v * v for v in vals) / len(vals) / 70.0)
true_rms = sqrt(sum(float(Fraction(price(x + i * 1e-12)) - exact(x + i * 1e-12, 0)) ** 2
                    for i in range(100)) / 100)
assert 0.5 < eta / true_rms < 2.0     # the estimate matches the exact noise
print(f"noise: eta = {E(eta)} dollars from 4th differences of 400 prices, {eta / (eps * D[0]):.1f} eps P")
print(f"scale: (P/|P^(j)|)^(1/j) for j = 2, 3, 4: {sqrt(D[0] / D[2]):.4f}, "
      f"{cbrt(D[0] / abs(D[3])):.4f}, {sqrt(sqrt(D[0] / D[4])):.4f}")

h = 1e-12
v = fwd(price, x, h); vb = fwd(bp, 500.0, h) * 1e4
print(f"trillionth, decimal: slope {v:.7f}, rel error {E(rel(v, D[1]))}, "
      f"truncation part {E(h * D[2] / 2 / abs(D[1]))}")
st = (500.0 + h) - 500.0
print(f"trillionth, bp: slope {vb:.1f}, step taken {E(st, 6)} bp, {E((st - h) / h)} too long")
assert vb == 0.0 and rel(v, D[1]) > 1e5 * h * D[2] / 2 / abs(D[1])

Y = [0.049 + i * 1e-5 for i in range(201)]          # 201 yields, 0.049 to 0.051
T = {k: [deriv(y, k) for y in Y] for k in (1, 2)}
def rms(g, h, k, unit=1.0):         # typical relative error of rule g; h in x's units
    s = 0.0
    for y, t in zip(Y, T[k]):
        v = g(price, y, h) if unit == 1.0 else g(bp, y * unit, h) * unit ** k
        s += rel(v, t) ** 2
    return sqrt(s / len(Y))

rows = [("forward", fwd, 1, 1, D[2] / 2, 2.0), ("central", cen, 2, 1, D[3] / 6, 1.0),
        ("second", sec, 2, 2, D[4] / 12, 4.0)]
p10 = [1.0]
for _ in range(16): p10.append(p10[-1] * 10.0)
print("chart, log10 h: [" + ", ".join(f"{log10(1.0 / p10[j]):.0f}" for j in range(1, 13)) + "]")
print("rule     rule h   rms err  bp h     bp err   h* (eta) rms err  law      ratio best 10^-j rms err")
for name, g, p, k, A, B in rows:
    hr = pow2(root(eps, p + k) * x)
    hb = pow2(root(eps, p + k) * 500.0); er, eb = rms(g, hr, k), rms(g, hb, k, 1e4)
    hs = root(k * B * eta / (p * abs(A)), p + k)
    es = rms(g, hs, k); law = (1 + p / k) * abs(A) * (hs if p == 1 else hs * hs) / abs(D[k])
    errs = [rms(g, 1.0 / p10[j], k) for j in range(1, 16)]
    j = errs.index(min(errs)) + 1
    print(f"{name:8} {E(hr):8} {E(er):8} {E(hb):8} {E(eb):8} {E(hs):8} {E(es):8} {E(law):8} "
          f"{es / law:.2f}  {j:<10} {E(errs[j - 1])}")
    assert hs / 10 < 1.0 / p10[j] < hs * 10 and 0.3 < es / law < 1.0 and es < errs[j - 1]
    print(f"chart, {name}, [" + ", ".join(f"{log10(errs[i]):.2f}" for i in range(12)) + "]")

for base, label in [(2.0 ** -30, "2^-30"), (2.0 ** -40, "2^-40")]:
    a, b = rms(fwd, base, 1), rms(fwd, base * 1.0001, 1)
    print(f"step {label}: rms rel error {E(a)}; same step x1.0001: {E(b)}")
    assert b > 1.5 * a                # the inexact step is clearly worse
t8, r8, r9 = 1e-8 * D[2] / 2 / abs(D[1]), rms(fwd, 1e-8, 1), rms(fwd, 1e-9, 1)
print(f"powers of ten: 1e-8 truncation alone {E(t8)}; 1e-9 rms rel error {E(r9)}")
assert abs(r8 / t8 - 1) < 0.01 and r9 > 1.5 * rms(fwd, 2.0 ** -30, 1)   # 1e-8 too big; 1e-9 inexact

d = 0.005                           # prices quoted to the cent
q = lambda y: floor(price(y) * 100.0 + 0.5) / 100.0
hq = cbrt(3.0 * d / abs(D[3])); est = abs(D[3]) * hq * hq / 6 + d / hq   # the law's estimate
vq = [cen(q, x, h) for h in (1e-12, 1e-4, hq)]
print(f"cent quotes: 3 eta/|P3| = {E(3.0 * d / abs(D[3]))}, h* = {E(hq, 4)}, quotes {q(x - hq):.2f} and {q(x + hq):.2f}")
print(f"cent quotes: central at 1e-12 {vq[0]:.1f}; at 1 bp {vq[1]:.1f} (rel {E(rel(vq[1], D[1]))})")
print(f"cent quotes: best h {E(hq)}, slope {vq[2]:.1f}, error {abs(vq[2] - D[1]):.2f}, "
      f"estimate {est:.2f}, ratio {abs(vq[2] - D[1]) / est:.2f}")
assert vq[0] == 0.0 and abs(vq[2] - D[1]) <= est and rel(vq[1], D[1]) > 0.01
qe = lambda h: sqrt(sum((cen(q, y, h) - t) ** 2 for y, t in zip(Y, T[1])) / len(Y))   # typical, 201 yields
assert qe(hq) < 0.1 * qe(1e-4)      # the law's step beats a 1 bp bump tenfold, not by luck
a, w = 0.004, 1e-4
wig = lambda y: price(y) + a * sin(2.0 * pi * (y - x) / w)
vw = cen(wig, x, 1e-7)
print(f"wiggle a = {a}, w = {w}: slope gap {2 * pi * a / w:.1f}, computed {vw:.1f}")
assert abs((vw - D[1]) - 2 * pi * a / w) < 1.0

print(f"breaks: unscaled step sqrt(eps) on 500 bp: rms {E(rms(fwd, pow2(sqrt(eps)), 1, 1e4))}")
print(f"breaks: second derivative at central's step: rms {E(rms(sec, pow2(cbrt(eps) * x), 2))}")
hq2 = cbrt(3.0 * 0.0005 / abs(D[3])); qt = lambda y: floor(price(y) * 1000.0 + 0.5) / 1000.0
print(f"try: tenth-cent quotes: best h {E(hq2)}, error {abs(cen(qt, x, hq2) - D[1]):.2f}")
y0 = 0.0001; t0 = deriv(y0, 1)
print(f"try: yield 0.0001: forward rel error {E(rel(fwd(price, y0, pow2(sqrt(eps) * y0)), t0))}"
      f" with |x|; {E(rel(fwd(price, y0, pow2(sqrt(eps) * 0.05)), t0))} with x_typ 0.05")
print("ALL CHECKS PASS")
