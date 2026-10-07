# Barone-Adesi-Whaley American put -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area is a series written out here,
# the critical price is found twice (Newton, then bisection), and the honest reference
# is a Cox-Ross-Rubinstein tree that checks early exercise at every node.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def N(x):                                # area left of x: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

def d1(S, K, r, q, s, T): return (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
def euro_put(S, K, r, q, s, T):
    a = d1(S, K, r, q, s, T)
    return K * exp(-r * T) * N(-(a - s * sqrt(T))) - S * exp(-q * T) * N(-a)

def beta(r, q, s, h, sign=-1):           # roots of b^2 + (n-1) b - m/h = 0; sign -1 = negative root
    m, n = 2 * r / (s * s), 2 * (r - q) / (s * s)
    return (-(n - 1) + sign * sqrt((n - 1) ** 2 + 4 * m / h)) / 2

def gap(X, K, r, q, s, T, b):            # value matching: European + lump - exercise value, at X
    lump = -(X / b) * (1 - exp(-q * T) * N(-d1(X, K, r, q, s, T)))
    return euro_put(X, K, r, q, s, T) + lump - (K - X)

def newton(K, r, q, s, T, b, trace=None):
    binf = beta(r, q, s, 1.0); Sinf = K * binf / (binf - 1)          # the perpetual boundary
    X = Sinf + (K - Sinf) * exp(((r - q) * T - 2 * s * sqrt(T)) * K / (K - Sinf))    # BAW's seed
    if trace is not None: trace.append((0, X))
    for it in range(1, 50):
        a, eq = d1(X, K, r, q, s, T), exp(-q * T)
        slope = -eq * N(-a) * (1 - 1 / b) - (1 + eq * phi(a) / (s * sqrt(T))) / b + 1
        new = X - gap(X, K, r, q, s, T, b) / slope
        if trace is not None: trace.append((it, new))
        if abs(new - X) < 1e-12 * K: return new, it
        X = new
    return X, it

def bisect(K, r, q, s, T, b):            # second road to the same critical price
    lo, hi = 1.0, K
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if gap(mid, K, r, q, s, T, b) < 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def baw_put(S, K, r, q, s, T, b=None, X=None):
    b = beta(r, q, s, 1 - exp(-r * T)) if b is None else b
    X = newton(K, r, q, s, T, b)[0] if X is None else X
    if S <= X: return K - S                                          # exercise now
    A = -(X / b) * (1 - exp(-q * T) * N(-d1(X, K, r, q, s, T)))
    return euro_put(S, K, r, q, s, T) + A * (S / X) ** b

def tree_put(S, K, r, q, s, T, steps=2000):      # the honest road: backward, exercise checked everywhere
    dt = T / steps; u = exp(s * sqrt(dt)); d = 1 / u
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt)
    v = [max(K - S * u ** j * d ** (steps - j), 0.0) for j in range(steps + 1)]
    for i in range(steps - 1, -1, -1):
        v = [max(disc * (p * v[j + 1] + (1 - p) * v[j]), K - S * u ** j * d ** (i - j)) for j in range(i + 1)]
    return v[0]

S, K, r, q, s, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
h = 1 - exp(-r * T); m, n = 2 * r / s ** 2, 2 * (r - q) / s ** 2
b1, b2 = beta(r, q, s, h), beta(r, q, s, h, +1)
trace = []; X, _ = newton(K, r, q, s, T, b1, trace); Xb = bisect(K, r, q, s, T, b1)
A = -(X / b1) * (1 - exp(-q * T) * N(-d1(X, K, r, q, s, T)))
eu = euro_put(S, K, r, q, s, T); lump = A * (S / X) ** b1; baw = eu + lump
t2000, t4000 = tree_put(S, K, r, q, s, T), tree_put(S, K, r, q, s, T, 4000)
e = 1e-5; slope = (baw_put(X + 2 * e, K, r, q, s, T) - baw_put(X + e, K, r, q, s, T)) / e
binf = beta(r, q, s, 1.0); Sinf = K * binf / (binf - 1); perp = (K - Sinf) * (S / Sinf) ** binf
rows = [("m = 2r/sigma^2", m), ("n = 2(r-q)/sigma^2", n), ("h = 1 - e^-rT", h),
        ("beta1, negative root", b1), ("beta2, positive root", b2), ("perpetual boundary", Sinf)]
rows += [(f"Newton step {i}", x) for i, x in trace]
rows += [("S* by bisection", Xb), ("d1 at S*", d1(X, K, r, q, s, T)), ("A, lump at S*", A),
         ("(S/S*)^beta1", (S / X) ** b1), ("European put", eu), ("lump at S = 100", lump),
         ("BAW American put", baw), ("tree, 2000 steps", t2000), ("tree, 4000 steps", t4000),
         ("BAW - tree", baw - t2000), ("premium, tree", t2000 - eu),
         ("slope just above S*", slope), ("perpetual put, exact", perp),
         ("BAW at T = 200 years", baw_put(S, K, r, q, s, 200.0)),
         ("tree node visits", sum(range(1, 2001)))]
Xk = K; Ak = -(Xk / b1) * (1 - exp(-q * T) * N(-d1(Xk, K, r, q, s, T)))
bp = beta(r, q, s, 1.0); Xp = newton(K, r, q, s, T, bp)[0]
rows += [("wrong: positive root", eu - (X / b2) * (1 - exp(-q * T) * N(-d1(X, K, r, q, s, T))) * (S / X) ** b2),
         ("wrong: h = 1, own S*", baw_put(S, K, r, q, s, T, bp, Xp)), ("  its S*", Xp),
         ("wrong: S* = K, no Newton", eu + Ak * (S / Xk) ** b1),
         ("wrong: no floor, S = 70", euro_put(70.0, K, r, q, s, T) + A * (70.0 / X) ** b1),
         ("  tree at S = 70", tree_put(70.0, K, r, q, s, T))]
for name, v in rows: print(f"{name:<26}{v:>14}" if isinstance(v, int) else f"{name:<26}{v:>14.6f}")

print("\nerror table: K=100 r=5% q=2% sigma=20%, tree 2000 steps")
print(f"{'T':>5}{'S':>6}{'S*':>9}{'European':>10}{'BAW':>10}{'tree':>10}{'BAW-tree':>10}")
mats, spots, errs, worst = (0.25, 0.5, 1.0, 2.0, 3.0), (90.0, 100.0, 110.0), {}, 0.0
for Tm in mats:
    Xm = newton(K, r, q, s, Tm, beta(r, q, s, 1 - exp(-r * Tm)))[0]
    for Sp in spots:
        eu_m, b_m, t_m = euro_put(Sp, K, r, q, s, Tm), baw_put(Sp, K, r, q, s, Tm), tree_put(Sp, K, r, q, s, Tm)
        errs[(Tm, Sp)] = b_m - t_m; worst = max(worst, abs(b_m - t_m))
        print(f"{Tm:>5.2f}{Sp:>6.0f}{Xm:>9.2f}{eu_m:>10.4f}{b_m:>10.4f}{t_m:>10.4f}{b_m - t_m:>+10.4f}")
        assert b_m >= eu_m and b_m >= K - Sp, "American must beat European and exercise"
for Sp in spots:
    print(f"chart, error in cents, S = {Sp:.0f}: " + ", ".join(f"{100 * errs[(Tm, Sp)]:.2f}" for Tm in mats))

assert abs(X - Xb) < 1e-8, "Newton and bisection must find the same critical price"
assert abs(eu - 6.330080627550) < 1e-9, "European put against the house number"
assert abs(t2000 - 6.660226) < 5e-7 and abs(t4000 - t2000) < 1e-3, "tree: house number, and settled"
assert abs(baw - 6.672215293) < 1e-8, "BAW price against an independent implementation"
assert abs(baw - t2000) < 0.02, "BAW within two cents of the tree at the house option"
assert abs(slope + 1) < 1e-4, "smooth pasting: slope -1 just above S*"
assert abs(baw_put(S, K, r, q, s, 200.0) - perp) < 1e-3, "long life must reach the exact perpetual put"
assert 0.02 < worst < 0.20, "errors are cents, not zero and not dollars"
print("ALL CHECKS PASS")
