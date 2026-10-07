# Hull-White trinomial tree -- the check behind the card.  Standard library only.  Three roads: the fitted
# tree; Jamshidian's closed form (Hull-White fitted to a Vasicek curve is Vasicek); an implicit grid in r.
from math import exp, log, sqrt, ceil, pi
A, SIG, THETA, R0, K, FACE = 0.3, 0.01, 0.05, 0.04, 0.047, 1_000_000.0

def N(x):                                   # bell-curve area left of x, by its power series
    if abs(x) > 8: return 0.0 if x < 0 else 1.0
    term, s, k = x, x, 0
    while abs(term) > 1e-17:
        k += 1; term *= x * x / (2 * k + 1); s += term
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2 * pi)

def vbond(tau, r):                          # Vasicek zero-coupon bond, tau years, short rate r
    B = (1 - exp(-A * tau)) / A
    return exp((THETA - SIG * SIG / (2 * A * A)) * (B - tau) - SIG * SIG * B * B / (4 * A) - B * r)

def D(t): return vbond(t, R0)               # today's discount curve: the house Vasicek curve

def tree(n, sig=SIG, edges=True, fit=True, T=6.0):
    dt = T / n; M = exp(-A * dt) - 1; dx = sqrt(3 * sig * sig * (1 - exp(-2 * A * dt)) / (2 * A))
    jmax = ceil(0.184 / -M) if edges else n
    def br(j):                              # (child, weight) for the three branches out of rung j
        m = j * M; mm = m * m
        if j >= jmax:  return ((j, 7/6 + (mm + 3*m)/2), (j-1, -1/3 - mm - 2*m), (j-2, 1/6 + (mm + m)/2))
        if j <= -jmax: return ((j+2, 1/6 + (mm - m)/2), (j+1, -1/3 - mm + 2*m), (j, 7/6 + (mm - 3*m)/2))
        return ((j+1, 1/6 + (mm + m)/2), (j, 2/3 - mm), (j-1, 1/6 + (mm - m)/2))
    w = [min(i, jmax) for i in range(n + 1)]
    Q, alpha, pmin, Qs = [1.0], [], 1.0, []
    for i in range(n):                      # forward: fit alpha_i, then push state prices on
        a = log(sum(Q[j + w[i]] * exp(-j * dx * dt) for j in range(-w[i], w[i] + 1)) / D((i + 1) * dt)) / dt if fit else R0
        alpha.append(a); Qs.append(Q); nq = [0.0] * (2 * w[i + 1] + 1)
        for j in range(-w[i], w[i] + 1):
            for k, p in br(j):
                pmin = min(pmin, p); nq[k + w[i + 1]] += Q[j + w[i]] * p * exp(-(a + j * dx) * dt)
        Q = nq
    def back(i, v):                         # one step of backward induction, layer i+1 to layer i
        return [exp(-(alpha[i] + j * dx) * dt) * sum(p * v[k + w[i + 1]] for k, p in br(j)) for j in range(-w[i], w[i] + 1)]
    return dict(n=n, dt=dt, M=M, dx=dx, jmax=jmax, alpha=alpha, w=w, back=back, pmin=pmin, br=br, Qs=Qs)

def on_tree(t, dates, greedy=False, show=False, k=K):
    n, s, w = t['n'], t['n'] // 6, t['w']
    P = {}                                  # zero-coupon bond prices at each exercise layer
    for y in range(2, 7):
        v = [1.0] * (2 * w[y * s] + 1)
        for i in range(y * s - 1, s - 1, -1):
            v = t['back'](i, v)
            if i % s == 0: P[(i // s, y)] = v
    v = [0.0] * (2 * w[n] + 1)
    for i in range(n - 1, -1, -1):
        v = t['back'](i, v)
        e = i // s
        if i % s == 0 and e in dates:
            G = [max(1 - P[(e, 6)][x] - k * sum(P[(e, y)][x] for y in range(e + 1, 7)), 0.0) for x in range(len(v))]
            if show and e in (1, 5):
                for j in ((0, 1, 2, 3) if e == 1 else (-1, 0, 1)):
                    x = j + w[i]
                    print(f"year {e} rung {j:+d}: rate {100 * (t['alpha'][i] + j * t['dx']):.4f}%  exercise {G[x] * FACE:10.2f}  wait {v[x] * FACE:10.2f}")
            v = [G[x] if G[x] > 0 and (greedy or G[x] > v[x]) else v[x] for x in range(len(v))]
    return v[0]

def jamshidian(e):                          # European payer e-into-(6-e) as a put on a coupon bond
    c = {y: K + (1.0 if y == 6 else 0.0) for y in range(e + 1, 7)}
    lo, hi = -1.0, 1.0
    for _ in range(200):                    # bisection for the rate r* that prices the bond at par
        mid = 0.5 * (lo + hi)
        if sum(cy * vbond(y - e, mid) for y, cy in c.items()) > 1: lo = mid
        else: hi = mid
    tot = 0.0
    for y, cy in c.items():
        X = vbond(y - e, 0.5 * (lo + hi))
        sp = SIG * sqrt((1 - exp(-2 * A * e)) / (2 * A)) * (1 - exp(-A * (y - e))) / A
        h = log(D(y) / (D(e) * X)) / sp + sp / 2
        tot += cy * (X * D(e) * N(-h + sp) - D(y) * N(-h))
    return tot

def pde(dates, nr=401, lo=-0.11, hi=0.19, per_year=500):   # implicit grid for the term-structure equation
    dr, dt = (hi - lo) / (nr - 1), 1.0 / per_year
    r = [lo + i * dr for i in range(nr)]; v = [0.0] * nr
    for step in range(5 * per_year, -1, -1):
        e = step // per_year
        if step % per_year == 0 and e in dates:
            v = [max(v[i], 1 - vbond(6 - e, r[i]) - K * sum(vbond(y - e, r[i]) for y in range(e + 1, 7))) for i in range(nr)]
        if step == 0: break
        a, b, c, d = [0.0] * nr, [0.0] * nr, [0.0] * nr, [x / dt for x in v]
        for i in range(nr):
            mu, df = A * (THETA - r[i]), 0.5 * SIG * SIG / (dr * dr)
            if i == 0:        b[i], c[i] = 1 / dt + r[i] + mu / dr, -mu / dr
            elif i == nr - 1: a[i], b[i] = mu / dr, 1 / dt + r[i] - mu / dr
            else: a[i], b[i], c[i] = -(df - mu / (2 * dr)), 1 / dt + r[i] + 2 * df, -(df + mu / (2 * dr))
        for i in range(1, nr):              # tridiagonal solve (Thomas)
            m = a[i] / b[i - 1]; b[i] -= m * c[i - 1]; d[i] -= m * d[i - 1]
        v[nr - 1] = d[nr - 1] / b[nr - 1]
        for i in range(nr - 2, -1, -1): v[i] = (d[i] - c[i] * v[i + 1]) / b[i]
    return v[round((R0 - lo) / dr)]

ALL = {1, 2, 3, 4, 5}
t = tree(60); t30, t120 = tree(30), tree(120)
print("curve D(0.1), D(1), D(6)       ", f"{D(0.1):.6f} {D(1):.6f} {D(6):.6f}")
print("forward swap rate 1-into-5      ", f"{100 * (D(1) - D(6)) / sum(D(y) for y in range(2, 7)):.4f}%")
print("tree 60: dt, M, dx              ", f"{t['dt']:.6f} {t['M']:.6f} {t['dx']:.6f}")
print("tree 60: jmax                   ", t['jmax'])
for j in (0, 7):
    print(f"tree 60: weights at rung {j}      ", " ".join(f"{p:.6f}" for _, p in t['br'](j)))
print("tree 60: smallest weight        ", f"{t['pmin']:.6f}")
print("edge: 0.184/-M, sqrt(2/3), 7M, 3*7M", f"{0.184 / -t['M']:.2f} {sqrt(2 / 3):.6f} {7 * t['M']:.6f} {21 * t['M']:.6f}")
print("step 1: alpha_0, Q(1,-1..+1)    ", f"{100 * t['alpha'][0]:.4f}%", " ".join(f"{q:.6f}" for q in t['Qs'][1]))
print("step 2: alpha_1                 ", f"{100 * t['alpha'][1]:.4f}%")
print("chart, year                      0      1      2      3      4      5")
for lab, jj in (("top", 1), ("centre", 0), ("bottom", -1)):
    print(f"chart, {lab:<7} rate %          " + " ".join(f"{100 * (t['alpha'][i] + jj * t['w'][i] * t['dx']):6.2f}" for i in range(0, 60, 10)))
eu = [jamshidian(e) for e in range(1, 6)]
for e in range(1, 6): print(f"closed form European {e}-into-{6 - e}   ", f"{eu[e - 1] * FACE:10.2f}")
(e30, e60, e120), (b30, b60, b120) = ([on_tree(x, d) for x in (t30, t, t120)] for d in ({1}, ALL))
pe, pb = pde({1}), pde(ALL)
for lab, v in (("tree 30  European 1-into-5", e30), ("tree 60  European 1-into-5", e60), ("tree 120 European 1-into-5", e120),
               ("tree 2x120-60 European", 2 * e120 - e60), ("grid (PDE) European", pe),
               ("tree 30  Bermudan", b30), ("tree 60  Bermudan", b60), ("tree 120 Bermudan", b120),
               ("tree 2x120-60 Bermudan", 2 * b120 - b60), ("grid (PDE) Bermudan", pb), ("grid: Bermudan minus European", pb - pe),
               ("diff: grid - closed, European", pe - eu[0]), ("diff: tree 60 - closed, European", e60 - eu[0]),
               ("diff: tree 120 - closed, European", e120 - eu[0]), ("diff: tree 2x120-60 - closed", 2 * e120 - e60 - eu[0]),
               ("diff: tree 2x120-60 - grid, Bermudan", 2 * b120 - b60 - pb), ("diff: tree 60 Bermudan - European", b60 - e60),
               ("diff: tree 60 Bermudan - best European", b60 - max(eu)),
               ("wrong: exercise when in the money", on_tree(t, ALL, greedy=True)),
               ("wrong: no curve fit, centre at 4%", on_tree(tree(60, fit=False), ALL)),
               ("try: fixed rate 5%, tree 60 Bermudan", on_tree(t, ALL, k=0.05)),
               ("try: sigma 2%, tree 60 Bermudan", on_tree(tree(60, sig=0.02), ALL))):
    print(f"{lab:<38}", f"{v * FACE:10.2f}")
print("wrong: no edge turn, smallest weight  ", f"{tree(60, edges=False)['pmin']:.6f}", "; middle weight < 0 from rung", ceil(sqrt(2 / 3) / -t['M']))
on_tree(t, ALL, show=True)
z6 = [1.0] * 15
for i in range(59, -1, -1): z6 = t['back'](i, z6)
print("6-year zero: tree rollback, curve   ", f"{z6[0]:.9f} {D(6):.9f}")
assert abs(z6[0] - D(6)) < 1e-12,                  "tree rollback reprices the 6-year zero on the curve"
assert abs(pe - eu[0]) * FACE < 5,                  "grid European vs closed form"
assert abs(2 * e120 - e60 - eu[0]) * FACE < 10,     "extrapolated tree European vs closed form"
assert abs(2 * b120 - b60 - pb) * FACE < 15,        "extrapolated tree Bermudan vs grid Bermudan"
assert pb > max(eu) and b60 > max(eu),              "Bermudan worth more than its best European"
assert t['pmin'] > 0 > tree(60, edges=False)['pmin'] and all(abs(sum(p * (k - j) ** e for k, p in t['br'](j)) - (1, j * t['M'], 1 / 3 + (j * t['M']) ** 2)[e]) < 1e-12
           for j in range(-7, 8) for e in range(3)), "weights positive; every rung's branches match the step's mean and variance"
print("ALL CHECKS PASS")
