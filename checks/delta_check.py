# Delta -- the check behind the card.  Standard library only, nothing imported
# that already knows the answer.  The bell-curve area N(x) is its own power
# series; the tree, the integral and the root finder are loops written here.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height at x
def N(x):                                                        # area to the left of x, by series
    if abs(x) > 8.0: return 1.0 if x > 0 else 0.0                # beyond 8 the tail is under 1e-15
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        n += 1
        term *= -x * x * (2 * n - 1) / (2 * n * (2 * n + 1))
        total += term
    return 0.5 + total / sqrt(2.0 * pi)

def d1d2(S, K, r, q, s, T):
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
    return d1, d1 - s * sqrt(T)
def call(S, K, r, q, s, T):
    d1, d2 = d1d2(S, K, r, q, s, T)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def put(S, K, r, q, s, T):
    d1, d2 = d1d2(S, K, r, q, s, T)
    return K * exp(-r * T) * N(-d2) - S * exp(-q * T) * N(-d1)
def delta(S, K, r, q, s, T): return exp(-q * T) * N(d1d2(S, K, r, q, s, T)[0])

def tree_delta(S, K, r, q, s, T, steps=2000):
    # Road 3: Cox-Ross-Rubinstein tree; delta read off the two nodes one step in.
    dt = T / steps; u = exp(s * sqrt(dt)); d = 1.0 / u
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt)
    v = [max(S * u ** j * d ** (steps - j) - K, 0.0) for j in range(steps + 1)]
    for n in range(steps, 1, -1):
        v = [disc * (p * v[j + 1] + (1 - p) * v[j]) for j in range(n)]
    return (v[1] - v[0]) / (S * u - S * d)

def pathwise_delta(S, K, r, q, s, T, n=20000):
    # Road 4: delta = e^-rT * average of (S_T / S) over the paths that finish above K.
    ST = lambda z: S * exp((r - q - 0.5 * s * s) * T + s * sqrt(T) * z)
    lo, hi = -10.0, 10.0                                          # bisection for the crossing S_T = K
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if ST(mid) < K else (lo, mid)
    z0 = 0.5 * (lo + hi); b = 12.0; h = (b - z0) / n
    f = lambda z: ST(z) / S * phi(z)
    tot = f(z0) + f(b) + sum((4 if i % 2 else 2) * f(z0 + i * h) for i in range(1, n))
    return exp(-r * T) * tot * h / 3.0, z0

S, K, r, q, s, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
d1, d2 = d1d2(S, K, r, q, s, T)
eq, er = exp(-q * T), exp(-r * T)
dc = delta(S, K, r, q, s, T); dp = eq * (N(d1) - 1.0)
h = 0.01
dc_bump = (call(S + h, K, r, q, s, T) - call(S - h, K, r, q, s, T)) / (2 * h)
dp_bump = (put(S + h, K, r, q, s, T) - put(S - h, K, r, q, s, T)) / (2 * h)
d_tree = tree_delta(S, K, r, q, s, T)
d_path, z0 = pathwise_delta(S, K, r, q, s, T)
lhs, rhs = S * eq * phi(d1), K * er * phi(d2)
C0 = call(S, K, r, q, s, T)
gam = (call(S + 1, K, r, q, s, T) - 2 * C0 + call(S - 1, K, r, q, s, T))
rows = [("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("e^-qT", eq), ("e^-rT", er),
        ("1 call delta e^-qT N(d1)", dc), ("2 call delta, central bump", dc_bump),
        ("3 call delta, tree 2000 steps", d_tree), ("4 call delta, pathwise integral", d_path),
        ("  crossing z0 by bisection", z0), ("put delta e^-qT (N(d1) - 1)", dp),
        ("put delta, central bump", dp_bump), ("call delta - put delta", dc_bump - dp_bump),
        ("density: S e^-qT phi(d1)", lhs), ("density: K e^-rT phi(d2)", rhs),
        ("call price C", C0), ("put price P", put(S, K, r, q, s, T)),
        ("hedge: shares bought, $", dc * S), ("hedge: cash borrowed, $", C0 - dc * S)]
for name, v in rows: print(f"{name:<34} {v:>12.6f}")
print("instant move: unhedged | hedged e^-qT N(d1) | hedged N(d1) | hedged N(d2)")
res = {}
for m in (-5.0, -1.0, 1.0, 5.0):
    dC = call(S + m, K, r, q, s, T) - C0                          # short one call, so we lose dC
    res[m] = [x * m - dC for x in (0.0, dc, N(d1), N(d2))]
    print(f"  move {m:+.0f}  " + "  ".join(f"{v:+10.6f}" for v in res[m]))
more = [("gamma by second difference, h=1", gam), ("  half gamma", 0.5 * gam),
        ("wrong: N(d1), no e^-qT", N(d1)), ("wrong: N(d2), exercise chance", N(d2)),
        ("wrong: put = minus call delta", -dc), ("wrong: put, sign dropped", eq * N(-d1)),
        ("wrong: one-sided bump, h=1", call(S + 1, K, r, q, s, T) - C0),
        ("deep in: S=1000", delta(1000.0, K, r, q, s, T)), ("far out: S=40", delta(40.0, K, r, q, s, T)),
        ("quarter year: delta at S=100", delta(S, K, r, q, s, 0.25)), ("quarter year: e^-qT", exp(-q * 0.25)),
        ("try: q=0", delta(S, K, r, 0.0, s, T)), ("try: sigma=0.40", delta(S, K, r, q, 0.40, T)),
        ("try: T=0.01", delta(S, K, r, q, s, 0.01)), ("try: K=120", delta(S, 120.0, r, q, s, T))]
for name, v in more: print(f"{name:<34} {v:>12.6f}")
xs = [80 + 5 * i for i in range(9)]
print("chart S       " + " ".join(f"{x:6d}" for x in xs))
print("chart price   " + " ".join(f"{call(x, K, r, q, s, T):6.2f}" for x in xs))
print("chart tangent " + " ".join(f"{C0 + dc * (x - S):6.2f}" for x in xs))
ys = [60 + 10 * i for i in range(11)]
print("delta S       " + " ".join(f"{y:6d}" for y in ys))
for lab, t in (("per100 T=1.00", 1.0), ("per100 T=0.25", 0.25)):
    print(lab + " " + " ".join(f"{100 * delta(y, K, r, q, s, t):6.2f}" for y in ys))
print(f"ceiling per100 T=1.00 {100 * eq:6.2f}")
assert abs(dc - 0.586851146135) < 1e-9, "formula vs the house delta"
assert abs(dc_bump - dc) < 1e-6, "central bump vs formula"
assert abs(d_tree - dc) < 1e-3, "tree vs formula"
assert abs(d_path - dc) < 1e-7, "pathwise integral vs formula"
assert abs((dc_bump - dp_bump) - eq) < 1e-6, "bumped call minus bumped put vs e^-qT"
assert abs(lhs - rhs) < 1e-9, "the density cancellation"
assert abs(res[1.0][1] + 0.5 * gam) < 1e-3, "hedged residual is about minus half gamma"
print("ALL CHECKS PASS")
