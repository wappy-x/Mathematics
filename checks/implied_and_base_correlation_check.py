# Implied (compound) and base correlation in the large-pool Gaussian copula.
# Pool: default chance P over the life, loss given default G = 1 - 40% recovery.
from math import exp, sqrt, pi
P, G = 0.05, 0.60

def npdf(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def ncdf(x):                                   # own normal CDF: series, then continued fraction
    u = abs(x)
    if u < 3.0:
        term = s = u; k = 1
        while term > 1e-17 * s: term *= u * u / (2 * k + 1); s += term; k += 1
        tail = 0.5 - npdf(u) * s
    else:
        cf = u
        for k in range(120, 0, -1): cf = u + k / cf
        tail = npdf(u) / cf
    return tail if x < 0 else 1.0 - tail
def ninv(p):                                   # inverse CDF by bisection
    lo, hi = -10.0, 10.0
    for _ in range(100):
        m = 0.5 * (lo + hi)
        if ncdf(m) < p: lo = m
        else: hi = m
    return 0.5 * (lo + hi)
def simpson(f, lo, hi, n):
    h = (hi - lo) / n
    return h / 3 * (f(lo) + f(hi) + sum((4 if j % 2 else 2) * f(lo + j * h) for j in range(1, n)))

C0 = ninv(P)                                   # default threshold c
def zcut(K, rho): return (C0 - sqrt(1 - rho) * ninv(K / G)) / sqrt(rho)
def F(K, rho):                                 # road 1: E[min(L, K)] averaged over the market factor
    if K <= 0.0: return 0.0
    if rho <= 0.0: return min(G * P, K)
    if rho >= 1.0: return P * min(G, K)
    z = min(max(zcut(K, rho), -9.0), 9.0)      # cut the factor range at 9 standard deviations
    loss = lambda x: G * ncdf((C0 - sqrt(rho) * x) / sqrt(1 - rho)) * npdf(x)
    return K * ncdf(z) + simpson(loss, z, 9.0, 2000)
def F2(K, rho):                                # road 2: bivariate normal CDF by Plackett's identity
    z, r = zcut(K, rho), sqrt(rho)
    dens = lambda s: exp(-(C0 * C0 - 2 * s * C0 * z + z * z) / (2 * (1 - s * s))) / (2 * pi * sqrt(1 - s * s))
    return K * ncdf(z) + G * (P - ncdf(C0) * ncdf(z) - simpson(dens, 0.0, r, 2000))
def M(A, B, rho): return (F(B, rho) - F(A, rho)) / (B - A)
def dF(K, rho): return -G * npdf(ninv(K / G)) * npdf(zcut(K, rho)) / (2 * sqrt(rho * (1 - rho)))
def dM(A, B, rho): return (dF(B, rho) - (dF(A, rho) if A > 0 else 0.0)) / (B - A)
def peak_rho(A, B):                            # closed form; None when the tranche has no hump
    bs = (ninv(A / G) if A > 0 else -1e9) + ninv(B / G)
    return 1 - (bs / (2 * C0)) ** 2 if 2 * C0 < bs < 0 else None

def bisect(f, lo, hi, n=60):                   # road 1 for every inverse: halve a sign-changing bracket
    flo = f(lo)
    for _ in range(n):
        m = 0.5 * (lo + hi)
        if (f(m) > 0) == (flo > 0): lo = m
        else: hi = m
    return 0.5 * (lo + hi)
def newton(f, df, lo, hi):                     # road 2: Newton with the analytic slope, kept in the branch
    x = 0.5 * (lo + hi)
    for _ in range(40):
        y = x - f(x) / df(x)
        x = y if lo < y < hi else 0.5 * (x + (lo if y <= lo else hi))
    return x
def compound(A, B, Q):                         # every correlation in (0,1) repricing the quote Q
    top = peak_rho(A, B) or 0.999999
    ends, out = [(1e-9, top)] + ([(top, 1.0)] if top < 0.999999 else []), []
    for lo, hi in ends:
        f = lambda r: M(A, B, r) - Q
        if f(lo) * f(hi) < 0:
            out.append((bisect(f, lo, hi), newton(f, lambda r: dM(A, B, r), lo, hi)))
    return out
def golden_max(f, lo, hi):                     # peak found numerically, no formula
    g = (sqrt(5) - 1) / 2
    for _ in range(80):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(a) < f(b): lo = a
        else: hi = b
    return 0.5 * (lo + hi)
def pool100(K, rho):                           # 100 loans, conditional binomial, same copula
    def f(x):
        q = ncdf((C0 - sqrt(rho) * x) / sqrt(1 - rho)); pr = (1 - q) ** 100; tot = 0.0
        for n in range(101):
            tot += pr * min(n * G / 100, K); pr *= (100 - n) / (n + 1) * q / (1 - q)
        return tot * npdf(x)
    return simpson(f, -9.0, 9.0, 800)

out = lambda label, v: print(f"{label:<40} {v:>12.6f}")
print(f"threshold c = N^-1(p)                    {C0:>12.6f}")
out("road 1 factor integral, 3-7% at 20%", M(0.03, 0.07, 0.2))
out("road 2 Plackett, 3-7% at 20%", (F2(0.07, 0.2) - F2(0.03, 0.2)) / 0.04)
out("road 1 equity 0-3% at 20%", F(0.03, 0.2) / 0.03); out("road 2 equity 0-3% at 20%", F2(0.03, 0.2) / 0.03)
out("b_A = N^-1(3% / g)", ninv(0.03 / G)); out("b_B = N^-1(7% / g)", ninv(0.07 / G))
out("100 loans, equity 0-3% at 20%", pool100(0.03, 0.2) / 0.03)
out("100 loans, 3-7% at 20%", (pool100(0.07, 0.2) - pool100(0.03, 0.2)) / 0.04)
h = 1e-5; fd = (F(0.07, 0.3 + h) - F(0.07, 0.3 - h)) / (2 * h)
out("slope dF/drho at 7%, 30%, formula", dF(0.07, 0.3)); out("slope dF/drho at 7%, 30%, bumped", fd)
rs, rg = peak_rho(0.03, 0.07), golden_max(lambda r: M(0.03, 0.07, r), 0.01, 0.99)
out("peak rho*, closed form", rs); out("peak rho*, golden section", rg); out("peak 3-7% loss", M(0.03, 0.07, rs))
grid = [i / 10 for i in range(10)]
print("chart, correlation %  " + " ".join(f"{100 * r:6.0f}" for r in grid))
print("chart, 3-7% loss %    " + " ".join(f"{100 * M(0.03, 0.07, r):6.2f}" for r in grid))
print("chart, 0-3% loss %    " + " ".join(f"{100 * F(0.03, r) / 0.03:6.2f}" for r in grid))
print("chart, quote lines %  " + " ".join(f"{v:6.2f}" for v in (19.5, 21.0)))
roots = {}
for label, A, B, Q in (("0-3% quote 62.80%", 0, 0.03, 0.628), ("3-7% quote = model at 20%", 0.03, 0.07, M(0.03, 0.07, 0.2)),
                       ("3-7% quote 19.50%", 0.03, 0.07, 0.195), ("3-7% quote 19.60%", 0.03, 0.07, 0.196),
                       ("3-7% quote 21.00%", 0.03, 0.07, 0.21)):
    roots[label] = compound(A, B, Q)
    print(f"{label:<27} roots: " + (", ".join(f"{b:.6f}/{n:.6f}" for b, n in roots[label]) or "none"))
naive = bisect(lambda r: M(0.03, 0.07, r) - 0.195, 0.0, 1.0)
out("wrong: one bracket 0..1 for 19.50%", naive); out("  its 3-7% loss", M(0.03, 0.07, naive))
Ks, seeds = [0.0, 0.03, 0.07, 0.10, 0.15], [None, 0.20, 0.25, 0.30, 0.40]
Cum = [0.0] + [F(Ks[i], seeds[i]) for i in range(1, 5)]
for i in range(1, 5):
    A, B = Ks[i - 1], Ks[i]; Q = (Cum[i] - Cum[i - 1]) / (B - A)
    fb = lambda r: F(B, r) - Cum[i]
    bb, bn = bisect(fb, 1e-9, 1.0 - 1e-9), newton(fb, lambda r: dF(B, r), 1e-6, 1.0 - 1e-6)
    cr = compound(A, B, Q)
    print(f"{f'{100 * A:.0f}-{100 * B:.0f}%':<7} quote {100 * Q:7.4f}%  cum {Cum[i]:.6f}  base {bb:.6f}/{bn:.6f}  compound "
          + ", ".join(f"{b:.4f}" for b, n in cr))
    assert abs(bb - seeds[i]) < 1e-8, "bisection bootstrap must return the correlation behind each quote"
    assert abs(bn - seeds[i]) < 1e-8, "Newton bootstrap must return the correlation behind each quote"
    assert 0 <= Cum[i] - Cum[i - 1] <= B - A, "cumulative losses must rise, and by no more than the width"
b5 = 0.20 + (0.05 - 0.03) / (0.07 - 0.03) * (0.25 - 0.20)
out("base correlation at 5%, interpolated", b5); out("first loss 0-5% at that correlation", F(0.05, b5))
out("5-10% by base correlation", (F(0.10, 0.30) - F(0.05, b5)) / 0.05)
out("wrong: 5-10% at flat 20%", M(0.05, 0.10, 0.20))
out("wrong: 5-10% at flat 30%", M(0.05, 0.10, 0.30))
out("5-7% by base correlation", (F(0.07, 0.25) - F(0.05, b5)) / 0.02)
for rho in (0.1, 0.2, 0.5, 0.9):
    assert abs(F(0.07, rho) - F2(0.07, rho)) < 1e-9, "factor integral vs Plackett bivariate normal"
assert abs(fd - dF(0.07, 0.3)) < 1e-6, "analytic slope vs bumped slope"
assert abs(rs - rg) < 1e-5, "closed-form peak vs numerical maximum"
for label, rr in roots.items():
    for b, n in rr: assert abs(b - n) < 1e-8, "bisection vs Newton on each branch: " + label
assert len(roots["3-7% quote 21.00%"]) == 0, "no correlation reprices 21%"
assert M(0.03, 0.07, rg) < 0.21, "21% lies above the numerically found hump"
assert abs(roots["3-7% quote = model at 20%"][0][0] - 0.2) < 1e-8, "the left root recovers the 20% that made the quote"
assert pool100(0.03, 0.2) < F(0.03, 0.2), "lumpy losses: 100 loans give the equity less loss (Jensen)"
assert abs(pool100(G, 0.2) - G * P) < 1e-9, "100 loans keep the pool's mean loss g p"
print("ALL CHECKS PASS")
