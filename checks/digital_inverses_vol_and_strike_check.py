# Digital inverses -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is the erf Taylor series written
# out, the quantile is Newton's method on it, the integral is Simpson's rule.
from math import log, sqrt, exp, pi, factorial

def N(x):                                     # bell-curve area left of x (series good for |x| <= 5)
    if abs(x) > 5.0: return 1.0 if x > 0 else 0.0   # off by < 3e-7; only the scan's sign test goes here
    y = x / sqrt(2.0)
    s = sum((-1) ** n * y ** (2 * n + 1) / (factorial(n) * (2 * n + 1)) for n in range(90))
    return 0.5 + s / sqrt(pi)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

def N_inv(p):                                 # Newton on N: the normal quantile
    x = 0.0
    for _ in range(60): x -= (N(x) - p) / phi(x)
    return x

S, r, q, T = 100.0, 0.05, 0.02, 1.0
D = exp(-r * T)                               # discount factor: $1 at expiry, today
F = S * exp((r - q) * T)                      # forward price

def cash(K, sig):                             # forward map: cash digital call paying $1
    w = sig * sqrt(T)
    return D * N((log(F / K) - 0.5 * w * w) / w)

def vols_quadratic(V, K):                     # Road 1: quantile, then w^2 + 2zw - 2m = 0
    z, m = N_inv(V / D), log(F / K)
    disc = z * z + 2.0 * m
    if disc < 0.0: return []
    big = -z - (1.0 if z >= 0.0 else -1.0) * sqrt(disc)   # the root with no cancellation
    roots = {big, -2.0 * m / big} if big != 0.0 else {0.0}
    return sorted(w / sqrt(T) for w in roots if w > 0.0)

def vols_scan(V, K):                          # Road 2: walk sigma, bisect each sign change
    f = lambda s: cash(K, s) - V
    found, grid = [], [0.005 + 0.01 * i for i in range(300)]
    for a, b in zip(grid, grid[1:]):
        if f(a) * f(b) < 0.0:
            for _ in range(60):
                mid = 0.5 * (a + b)
                if f(a) * f(mid) <= 0.0: b = mid
                else: a = mid
            found.append(0.5 * (a + b))
    return found

def rule(V, K):                               # the moneyness table, no roots computed
    z, m = N_inv(V / D), log(F / K)
    if m > 0.0: return 1
    if m == 0.0: return 1 if z < 0.0 else 0
    k = sqrt(-2.0 * m)                        # the turning width
    return 2 if z < -k else (1 if z == -k else 0)

def density_price(K, sig, n=4000):            # Road 3: average the payoff over log-price at expiry
    w = sig * sqrt(T)
    c = log(F) - 0.5 * w * w                  # centre of ln(S_T) in the pricing world
    a, b = log(K), c + 12.0 * w
    g = lambda u: phi((u - c) / w) / w
    h = (b - a) / n
    tot = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return D * tot * h / 3.0

def strike_closed(V, sig):                    # K = F exp(-w z - w^2/2)
    w, z = sig * sqrt(T), N_inv(V / D)
    return F * exp(-w * z - 0.5 * w * w)

def strike_bisect(V, sig):                    # price falls as the strike rises
    lo, hi = 50.0, 200.0
    for _ in range(100):
        mid = sqrt(lo * hi)
        if cash(mid, sig) > V: lo = mid
        else: hi = mid
    return sqrt(lo * hi)

V = cash(100.0, 0.20)                         # the house quote
w1, w2, K1 = vols_quadratic(V, 100.0), vols_scan(V, 100.0), strike_closed(V, 0.20)
V110 = cash(110.0, 0.20)
r110, s110 = vols_quadratic(V110, 110.0), vols_scan(V110, 110.0)
m110 = log(F / 110.0)
k110 = sqrt(-2.0 * m110)                      # the turning width
z_one = N_inv(V)                              # wrong: normalised by $1, not by D
rows = [
    ("discount D = e^-rT", D), ("forward F = S e^(r-q)T", F), ("quote V, house cash digital", V),
    ("normalised quote y = V/D", V / D), ("z = N^-1(y)", N_inv(V / D)), ("m = ln(F/K), K = 100", log(F / 100.0)),
    ("1 vol by quadratic", w1[0]), ("  its other root, discarded", -2.0 * log(F / 100.0) / w1[0]),
    ("2 vol by scan and bisection", w2[0]), ("  roots the scan found", len(w2)),
    ("3 price at that vol, by integral", density_price(100.0, w1[0])),
    ("1 strike, closed form", K1), ("2 strike, bisection", strike_bisect(V, 0.20)),
    ("3 price at that strike, by integral", density_price(K1, 0.20)),
    ("K = 110: m", m110), ("K = 110: quote at 20%", V110), ("K = 110: z", N_inv(V110 / D)),
    ("K = 110: small root", r110[0]), ("K = 110: large root", r110[1]), ("K = 110: roots multiply to -2m", -2.0 * m110),
    ("K = 110: scan, small", s110[0]), ("K = 110: scan, large", s110[1]),
    ("K = 110: price at large root, integral", density_price(110.0, r110[1])),
    ("K = 110: turning vol sqrt(-2m)", k110), ("K = 110: top quote D N(-k)", D * N(-k110)),
    ("m = 0 ceiling, D/2", 0.5 * D), ("K where 20% is the turn, F e^(w^2/2)", F * exp(0.02)),
    ("wrong: normalised by $1", -z_one + sqrt(z_one * z_one + 0.06)),
    ("wrong: spot for forward, strike", S * exp(-0.2 * N_inv(V / D) - 0.02)),
    ("try: K = 120, large root", vols_quadratic(cash(120.0, 0.2), 120.0)[1]),
    ("try: strike for a $0.25 quote", strike_closed(0.25, 0.20)),
    ("try: strike from the put 0.456648", strike_closed(D - 0.456648, 0.20)),
    ("  house digital put D - V", D - V),
]
za = N_inv(V / D)                             # wrong: asset formula, w^2 - 2zw + 2m = 0
rows.append(("wrong: d1 formula, real roots", "none" if za * za - 0.06 < 0 else "some"))
for name, v in rows: print(f"{name:<40} {v:>12.6f}" if isinstance(v, float) else f"{name:<40} {v:>12}")
print()
cases = [(100.0, V), (90.0, 0.70), (F, 0.40), (F, 0.48), (110.0, 0.25), (110.0, 0.34), (110.0, 0.35)]
for K, Vq in cases:
    a, b, c = rule(Vq, K), len(vols_quadratic(Vq, K)), len(vols_scan(Vq, K))
    print(f"count  K {K:7.2f}  quote {Vq:.6f}   rule {a}  quadratic {b}  scan {c}")
    assert a == b == c, "moneyness rule, quadratic and scan must agree on the count"
print()
sigs = [0.1 * i for i in range(1, 11)]
print(f"{'chart, vol %':<22}" + "".join(f"{100 * s:7.0f}" for s in sigs))
print(f"{'chart, K 100 cents':<22}" + "".join(f"{100 * cash(100.0, s):7.2f}" for s in sigs))
print(f"{'chart, K 110 cents':<22}" + "".join(f"{100 * cash(110.0, s):7.2f}" for s in sigs))
print(f"{'chart, quote cents':<22}" + "".join(f"{100 * V110:7.2f}" for s in sigs))
print(f"figure, K 100 crossing   w {w1[0]:.4f}  z {N_inv(V / D):.4f}")
print(f"figure, K 110 crossings  w {r110[0]:.4f} and {r110[1]:.4f}  z {N_inv(V110 / D):.4f}")
print(f"figure, K 110 peak       w {k110:.4f}  z {-k110:.4f}")

assert abs(V - 0.494581) < 5e-7, "house cash digital, as quoted on the shelf"
assert len(w2) == 1 and abs(w1[0] - w2[0]) < 1e-9, "K = 100: one vol, quadratic vs scan"
assert len(s110) == 2 and all(abs(a - b) < 1e-9 for a, b in zip(r110, s110)), "K = 110: two vols, both roads"
assert abs(density_price(110.0, r110[1]) - V110) < 1e-9, "the second vol reprices the same quote"
assert abs(K1 - strike_bisect(V, 0.20)) < 1e-6 and abs(K1 - 100.0) < 1e-6, "strike: closed form vs bisection"
assert abs(max(cash(110.0, 0.3 + 1e-4 * i) for i in range(1200)) - D * N(-k110)) < 1e-8, "K = 110: scanned top quote is D N(-k)"
print("ALL CHECKS PASS")
