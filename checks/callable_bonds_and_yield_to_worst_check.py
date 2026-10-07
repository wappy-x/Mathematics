# Callable bond and yield to worst -- the check behind the card.  Standard library only.  10-year 6% bond,
# callable at 100 just after the coupon in years 5-9.  Roads: (1) Hull-White tree, min(100, keep); (2) curve
# bond minus the issuer's option; (3) forward ledger; (4) Jamshidian for the year-5-only call.  Yields: two roots.
from math import exp, log, sqrt, pi
F, CPN, K, A, SIG = 100.0, 6.0, 100.0, 0.2, 0.01          # face, coupon, call price, reversion, rate vol
def D(t, sh=0.0): return exp(-(0.03 + sh) * t - 0.002 * t * t)   # today's discount curve
def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def N(x):                                                  # normal CDF by Simpson's rule, 0 to x
    if abs(x) > 10: return 1.0 if x > 0 else 0.0
    h = x / 2000
    return 0.5 + h / 3 * sum((1 if i in (0, 2000) else 4 if i % 2 else 2) * phi(i * h) for i in range(2001))
def weights(offs, m):              # branch weights with mean m and variance 1/3, in rungs
    s2, out = 1 / 3 + m * m, []
    for a in offs:
        b, c = [o for o in offs if o != a]
        out.append((s2 - (b + c) * m + b * c) / ((a - b) * (a - c)))
    return out
def tree(n, sig, sh):
    dt = 10.0 / n; M = exp(-A * dt) - 1
    dx = sqrt(3 * sig * sig * (1 - exp(-2 * A * dt)) / (2 * A))
    jm = int(0.184 / -M) + 1
    br = {}
    for j in range(-jm, jm + 1):
        offs = (0, -1, -2) if j == jm else (2, 1, 0) if j == -jm else (1, 0, -1)
        br[j] = [(j + o, p) for o, p in zip(offs, weights(offs, j * M))]
    Q, al = {0: 1.0}, []
    for i in range(n):                                     # fit one shift per layer to the curve
        al.append(log(sum(q * exp(-j * dx * dt) for j, q in Q.items()) / D((i + 1) * dt, sh)) / dt)
        nq = {}
        for j, q in Q.items():
            for k, p in br[j]: nq[k] = nq.get(k, 0.0) + q * p * exp(-(al[i] + j * dx) * dt)
        Q = nq
    return dt, dx, jm, br, al
def price(n, sig=SIG, sh=0.0, dates=(5, 6, 7, 8, 9), below=None):   # below: naive rule, call if rate < it
    dt, dx, jm, br, al = tree(n, sig, sh); st = n // 10
    S = {j: F + CPN for j in range(-jm, jm + 1)}; C = dict(S); O = {j: 0.0 for j in S}
    calls, layer5 = set(), []
    for i in range(n - 1, -1, -1):
        cpn = CPN if i > 0 and i % st == 0 else 0.0
        can = i % st == 0 and i // st in dates
        nS, nC, nO = {}, {}, {}
        for j in range(-min(i, jm), min(i, jm) + 1):
            d = exp(-(al[i] + j * dx) * dt)
            s, c, o = (d * sum(p * V[k] for k, p in br[j]) for V in (S, C, O))
            nS[j] = cpn + s
            if below is not None: nC[j] = cpn + (K if can and al[i] + j * dx < below else c)
            else: nC[j] = cpn + (min(K, c) if can else c)
            nO[j] = max(s - K, o) if can else o
            if can and c > K: calls.add((i, j))
            if i == 5 * st: layer5.append((100 * (al[i] + j * dx), s, min(K, c)))
        S, C, O = nS, nC, nO
    led, live = 0.0, {0: 1.0}                                # road 3: follow the money forward
    for i in range(n + 1):
        if i > 0 and i % st == 0: led += CPN * sum(live.values())
        if i == n: led += F * sum(live.values()); break
        nl = {}
        for j, q in live.items():
            if (i, j) in calls: led += K * q; continue
            for k, p in br[j]: nl[k] = nl.get(k, 0.0) + q * p * exp(-(al[i] + j * dx) * dt)
        live = nl
    return S[0], C[0], O[0], led, len(calls), layer5, jm, dx, al
def jamshidian(T=5):               # road 4: European call at year 5 on the years 6-10 cash flows
    B = lambda t, u: (1 - exp(-A * (u - t))) / A
    lnA = lambda t, u: log(D(u) / D(t)) + B(t, u) * (0.03 + 0.004 * t) - SIG**2 / (4 * A) * (1 - exp(-2 * A * t)) * B(t, u)**2
    cf = [(u, CPN + (F if u == 10 else 0.0)) for u in range(T + 1, 11)]
    bond = lambda r: sum(c * exp(lnA(T, u) - B(T, u) * r) for u, c in cf)
    lo, hi = -1.0, 1.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if bond(mid) > K else (lo, mid)
    tot = 0.0
    for u, c in cf:
        X = exp(lnA(T, u) - B(T, u) * lo)
        sp = SIG * sqrt((1 - exp(-2 * A * T)) / (2 * A)) * B(T, u)
        h = log(D(u) / (X * D(T))) / sp + sp / 2
        tot += c * (D(u) * N(h) - X * D(T) * N(h - sp))
    return tot, 100 * lo
def fixed(e, y): return sum(CPN / (1 + y)**t for t in range(1, e + 1)) + F / (1 + y)**e
def y_bisect(e, P):
    lo, hi = -0.5, 1.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if fixed(e, mid) > P else (lo, mid)
    return (lo + hi) / 2
def y_newton(e, P):
    y = 0.05
    for _ in range(50):
        dP = -sum(t * CPN / (1 + y)**(t + 1) for t in range(1, e + 1)) - e * F / (1 + y)**(e + 1)
        y -= (fixed(e, y) - P) / dP
    return y
S0, C0, O0, led, ncalls, layer5, jm, dx, al = price(400)
curve = sum(CPN * D(t) for t in range(1, 11)) + F * D(10)
eur = S0 - price(400, dates=(5,))[1]; jam, rstar = jamshidian()
sched = [sum(CPN * D(t) for t in range(1, e + 1)) + F * D(e) for e in range(5, 11)]
flat = price(400, sig=0.0)[1]
print(f"{'tree: steps, edge rung, rung spacing %':<40} 400 {jm} {100 * dx:.6f}")
sD = sum(D(t) for t in range(1, 11))
print(f"{'curve: D(10), sum D(1..10), 6x, 100xD(10)':<40} {D(10):.6f} {sD:.6f} {6 * sD:.6f} {100 * D(10):.6f}")
for lab, v in (("1 straight bond, from the curve", curve), ("  straight bond, rolled back on tree", S0),
               ("1 callable, tree, 400 steps", C0), ("  callable, tree, 100 steps", price(100)[1]),
               ("  callable, tree, 200 steps", price(200)[1]),
               ("2 issuer's call option, own recursion", O0), ("  straight minus option", S0 - O0),
               ("3 callable, forward ledger", led), ("4 year-5-only call, tree", eur),
               ("  year-5-only call, Jamshidian", jam), ("  critical rate r* at year 5, %", rstar),
               ("  Bermudan call minus year-5-only call", O0 - eur),
               ("zero vol: callable on tree", flat), ("zero vol: cheapest fixed schedule", min(sched))):
    print(f"{lab:<40} {v:12.6f}")
print(f"{'call nodes on the 400-step tree':<40} {ncalls}")
print("fixed schedules on the curve, called at 5..9, maturity 10:")
print("  " + " ".join(f"{v:.4f}" for v in sched))
Y = [(y_bisect(e, C0), y_newton(e, C0)) for e in range(5, 11)]
print(f"yields at the model price {C0:.6f}, percent, bisection | Newton:")
for e, (yb, yn) in zip(range(5, 11), Y): print(f"  {'to call, year ' + str(e) if e < 10 else 'to maturity, year 10':<22} {100 * yb:.6f}  {100 * yn:.6f}")
ytw = min(yb for yb, _ in Y); v5 = (1 + ytw)**-5
print(f"{'yield to worst %, and its year':<40} {100 * ytw:.6f} {5 + [yb for yb, _ in Y].index(ytw)}")
print(f"{'  at it: (1+y)^-5, a_5, 6 a_5, 100 v^5':<40} {v5:.6f} {(1 - v5) / ytw:.6f} {6 * (1 - v5) / ytw:.6f} {100 * v5:.6f}")
for P in (100.0, 95.0):
    ys = [y_bisect(e, P) for e in range(5, 11)]
    print(f"at price {P:.2f}: yields % " + " ".join(f"{100 * y:.4f}" for y in ys) + f"  worst year {5 + ys.index(min(ys))}")
print(f"{'wrong: ignore the call (straight price)':<40} {S0:12.6f}")
print(f"{'wrong: call whenever rate < 6%':<40} {price(400, below=0.06)[1]:12.6f}")
print(f"{'wrong: only the first call date':<40} {S0 - eur:12.6f}")
print(f"{'wrong: quote yield to maturity, %':<40} {100 * Y[5][0]:12.6f}")
g = {}
for lab, kw in (("curve -1%", dict(sh=-0.01)), ("curve +1%", dict(sh=0.01)), ("vol 0.5%", dict(sig=0.005)), ("vol 2%", dict(sig=0.02))):
    s, c = price(400, **kw)[:2]; g[lab] = (s, c)
    print(f"{'greeks: ' + lab + ', straight | callable':<40} {s:10.4f} {c:10.4f}")
for lab, P0, idx in (("straight", S0, 0), ("callable", C0, 1)):
    print(f"{'effective duration, ' + lab:<40} {(g['curve -1%'][idx] - g['curve +1%'][idx]) / (2 * P0 * 0.01):10.4f}")
print("chart, year 5 after coupon: rate %, straight, callable (rungs -16 to 16, every 4th)")
for row in zip(*layer5[jm - 16:jm + 17:4]): print("  " + " ".join(f"{v:7.2f}" for v in row))
assert abs(S0 - curve) < 1e-9, "tree must reprice the straight bond the curve prices"
assert abs(led - C0) < 1e-9, "forward ledger vs rollback"
assert abs(S0 - O0 - C0) < 1e-9, "straight minus the separately rolled option vs rollback"
assert abs(eur - jam) < 5e-4, "tree's one-date call vs Jamshidian closed form"
assert abs(flat - min(sched)) < 1e-9, "zero vol: tree equals cheapest fixed schedule"
assert all(abs(yb - yn) < 1e-12 for yb, yn in Y), "yield by bisection vs Newton"
assert all(abs(y_newton(e, 100.0) - 0.06) < 1e-12 for e in range(5, 11)), "at par every yield is the coupon rate"
print("ALL CHECKS PASS")
