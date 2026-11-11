# Convergence rates -- the check behind the card.  Standard library only.
# Part 1: an error that halves each step against one that squares, from 0.1.
# Part 2: the Rosenbrock valley f = (1 - x1)^2 + b (x2 - x1^2)^2, b = 100, written
# with x = x1, y = x2 below, minimised at (1, 1).  Roads: the rate predicted from the condition number
# against the rate measured from gradient descent's own errors; Newton's
# constant predicted from derivatives against the measured one; orders
# measured from error sequences against the known 1, phi and 2.
import math

def sci(v):  # 3 significant figures, same text in Python and Rust
    e = math.floor(math.log10(v)); m = v / 10 ** e
    if m >= 9.995: m, e = m / 10, e + 1
    return f"{m:.2f}e{e}"

def order(es, i):  # p estimated from three successive errors
    return math.log(es[i + 1] / es[i]) / math.log(es[i] / es[i - 1])

def model(step, e0, tol):  # run an error map until the error drops below tol
    es = [e0]
    while es[-1] >= tol: es.append(step(es[-1]))
    return es

# ---- 1. halving against squaring ----
half, sq = model(lambda e: e / 2, 0.1, 1e-12), model(lambda e: e * e, 0.1, 1e-12)
print("chart, halving digits", " ".join(f"{-math.log10(0.1 / 2 ** k):.2f}" for k in range(7)))
print("chart, squaring digits", " ".join(f"{-math.log10(0.1) * 2 ** k:.0f}" for k in range(7)))
print(f"after 1 step: halving {sci(half[1])}, squaring {sci(sq[1])}; after 4: halving {sci(half[4])}, squaring {sci(sq[4])}")
print(f"digits gained per step by halving {-math.log10(0.5):.3f}")
print(f"steps to error < 1e-12: halving {len(half) - 1}, squaring {len(sq) - 1}")
assert len(half) - 1 == math.ceil(math.log2(0.1 / 1e-12))   # 0.1 / 2^k < 1e-12
assert len(sq) - 1 == math.ceil(math.log2(12))             # 10^-(2^k) < 1e-12
print(f"order estimates: halving {order(half, 5):.3f}, squaring {order(sq, 2):.3f}")
assert abs(order(half, 5) - 1) < 1e-9
assert abs(order(sq, 2) - 2) < 1e-9

# ---- 2. the condition number at the bottom of the valley ----
def grad(x, y, b=100): return (-2 * (1 - x) - 4 * b * x * (y - x * x), 2 * b * (y - x * x))
def hess(x, y, b=100): return (2 - 4 * b * (y - x * x) + 8 * b * x * x, -4 * b * x, 2.0 * b)
def dist(x, y): return math.sqrt((x - 1) * (x - 1) + (y - 1) * (y - 1))
def eig(b):  # closed form for a symmetric 2x2: mean of the diagonal plus or minus a radius
    p, q, r = hess(1, 1, b); m, h = (p + r) / 2, (p - r) / 2
    rad = math.sqrt(h * h + q * q)
    return m + rad, m - rad
L, mu = eig(100); kap = L / mu
p, q, r = hess(1, 1); v = (1.0, 0.0)
for _ in range(60):  # power iteration: an independent road to L
    w = (p * v[0] + q * v[1], q * v[0] + r * v[1]); n = math.sqrt(w[0] * w[0] + w[1] * w[1]); v = (w[0] / n, w[1] / n)
Lpow = v[0] * (p * v[0] + q * v[1]) + v[1] * (q * v[0] + r * v[1])
print(f"Hessian at (1, 1): {p:.0f} {q:.0f} {r:.0f}; L {L:.4f} (power iteration {Lpow:.4f}), mu {mu:.6f}")
assert abs(Lpow - L) < 1e-6
assert abs((p - mu) * (r - mu) - q * q) < 1e-6              # mu really is an eigenvalue
print(f"by hand: mean {(p + r) / 2:.0f}, half-gap {(p - r) / 2:.0f}, radius {L - (p + r) / 2:.4f}; step 1/L {1 / L:.6f}; ln 10 {math.log(10):.3f}")
rate, best = 1 - 1 / kap, (kap - 1) / (kap + 1)
spd = lambda c: math.log(10) / -math.log(c)                 # steps per decimal digit
print(f"kappa {kap:.2f}; predicted rate 1 - 1/kappa {rate:.6f}, {spd(rate):.0f} steps per digit")
print(f"best fixed step 2/(L + mu): rate {best:.6f}, {spd(best):.0f} steps per digit")

def gd(x, y, tol, b=100, best=False):  # fixed step 1/L (or 2/(L + mu)); error = distance to (1, 1)
    Lb, mb = eig(b); a = 2 / (Lb + mb) if best else 1 / Lb; es = [dist(x, y)]
    while es[-1] >= tol:
        g = grad(x, y, b); x, y = x - a * g[0], y - a * g[1]
        es.append(dist(x, y))
    return es
es = gd(-1.2, 1.0, 1e-6)
print(f"GD from (-1.2, 1): {len(es) - 1} steps to error < 1e-6; last ratio {es[-1] / es[-2]:.6f}")
print("GD error at k = 0, 1000, 10000, 20000, 30000:", " ".join(sci(es[k]) for k in (0, 1000, 10000, 20000, 30000)))
k3, k6 = next(k for k, e in enumerate(es) if e < 1e-3), len(es) - 1
print(f"steps from 1e-3 to 1e-6: measured {k6 - k3}, predicted {3 * spd(rate):.0f}")
assert abs(es[-1] / es[-2] - rate) < 1e-6                   # measured rate = condition-number rate
assert abs((k6 - k3) / (3 * spd(rate)) - 1) < 0.01

def newton(x, y, tol):
    es = [dist(x, y)]
    while es[-1] >= tol:
        g = grad(x, y); a, c, d = hess(x, y); det = a * d - c * c
        x, y = x - (d * g[0] - c * g[1]) / det, y - (a * g[1] - c * g[0]) / det
        es.append(dist(x, y))
    return es
ne = newton(-1.2, 1.0, 1e-6)
print(f"Newton from (-1.2, 1): {len(ne) - 1} steps; errors", " ".join(sci(e) for e in ne))

# ---- 3. measuring the order on the valley's slice y = 1: h'(x) = 400x^3 - 398x - 2 ----
dh, d2h, d3h = (lambda x: 400 * x * x * x - 398 * x - 2), (lambda x: 1200 * x * x - 398), (lambda x: 2400 * x)
x, nt = 1.2, [0.2]
while nt[-1] > 1e-9: x = x - dh(x) / d2h(x); nt.append(abs(x - 1))
x0, x1, se = 1.2, 1.1, [0.2, 0.1]
while se[-1] > 1e-9: x0, x1 = x1, x1 - dh(x1) * (x1 - x0) / (dh(x1) - dh(x0)); se.append(abs(x1 - 1))
M = d3h(1) / (2 * d2h(1))
print("slice Newton errors", " ".join(sci(e) for e in nt), "| secant", " ".join(sci(e) for e in se))
print("Newton e(k+1)/e(k)^2:", " ".join(f"{nt[i + 1] / (nt[i] * nt[i]):.4f}" for i in range(len(nt) - 1)), f"| predicted {M:.4f}")
print("order estimates: Newton", " ".join(f"{order(nt, i):.3f}" for i in range(1, len(nt) - 1)),
      "| secant", " ".join(f"{order(se, i):.3f}" for i in range(1, len(se) - 1)))
assert abs(nt[-1] / (nt[-2] * nt[-2]) - M) < 0.01
assert abs(order(nt, len(nt) - 2) - 2) < 0.05
assert abs(order(se, len(se) - 2) - (1 + math.sqrt(5)) / 2) < 0.05
print(f"golden ratio phi {(1 + math.sqrt(5)) / 2:.3f}; slice second derivative {d2h(1):.0f}, third {d3h(1):.0f}")

# ---- what breaks ----
x4 = model(lambda e: e - 4 * e * e * e / (12 * e * e), 1.0, 1e-6)   # Newton on x^4: flat bottom
rx, ry, rk = -1.2, 1.0, 0   # GD, step 1/L, on a round bowl (L/2)|x - (1, 1)|^2, where kappa = 1
while dist(rx, ry) >= 1e-6: rx, ry, rk = rx - L * (rx - 1) / L, ry - L * (ry - 1) / L, rk + 1
print(f"round-valley guess {rk} step, real {len(es) - 1}; kappa from L alone: {spd(1 - 1 / L):.0f} steps per digit")
print(f"Newton on x^4: ratio {x4[1] / x4[0]:.6f}, {len(x4) - 1} steps to 1e-6; early order estimate {order(ne, 1):.1f}")
assert abs(x4[1] / x4[0] - 2 / 3) < 1e-12
assert len(x4) - 1 == math.ceil(6 * math.log(10) / math.log(1.5))

# ---- try changing ----
b1 = eig(1); g1 = gd(-1.2, 1.0, 1e-6, b=1)
print(f"b = 1: kappa {b1[0] / b1[1]:.2f}, GD {len(g1) - 1} steps; tol 1e-9: GD {len(gd(-1.2, 1.0, 1e-9)) - 1}, Newton {len(newton(-1.2, 1.0, 1e-9)) - 1}")
print(f"step 2/(L + mu): GD {len(gd(-1.2, 1.0, 1e-6, best=True)) - 1} steps")
print("bars, steps per digit:", " ".join(f"kappa {c}: {spd(1 - 1 / c):.1f}" for c in (2, 10, 100, 1000)), f"kappa {kap:.0f}: {spd(rate):.1f}")
print("ALL CHECKS PASS")
