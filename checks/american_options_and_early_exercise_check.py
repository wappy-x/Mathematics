# American put: the price is the best stopping rule, found by working backwards.
# Standard library only. Roads: (1) CRR tree with a max at every node, (2) a
# Crank-Nicolson grid solved by Brennan-Schwartz, (3) fixed stopping rules on the
# same tree, each a lower bound. Our own normal CDF (Simpson), no erf.
from math import exp, log, sqrt, pi

def ncdf(x, n=2000):                        # area under the bell curve left of x
    if x < 0: return 1.0 - ncdf(-x, n)
    h = x / n; f = lambda z: exp(-0.5 * z * z)
    s = f(0.0) + f(x) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n))
    return 0.5 + s * h / 3.0 / sqrt(2.0 * pi)

def bs(S, K, r, q, sig, T):                 # European call and put, closed form
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
    c = S * exp(-q * T) * ncdf(d1) - K * exp(-r * T) * ncdf(d2)
    p = K * exp(-r * T) * ncdf(-d2) - S * exp(-q * T) * ncdf(-d1)
    return c, p

def tree(S, K, r, q, sig, T, N, call=False, rule="best", level=0.0):
    # rule: "best" = max at every node; "never" = European; "level" = exercise
    # the first time Acme is at or below `level` (and the put pays something)
    dt = T / N; u = exp(sig * sqrt(dt)); p = (exp((r - q) * dt) - 1 / u) / (u - 1 / u)
    a, b = exp(-r * dt) * p, exp(-r * dt) * (1 - p)
    w = 1.0 if call else -1.0
    v = [max(w * (S * u ** (2 * j - N) - K), 0.0) for j in range(N + 1)]
    for n in range(N - 1, -1, -1):
        v = [b * v[j] + a * v[j + 1] for j in range(n + 1)]
        if rule == "never": continue
        for j in range(n + 1):
            s = S * u ** (2 * j - n); g = w * (s - K)
            if rule == "best":
                if g > v[j]: v[j] = g
            elif s <= level and g > 0: v[j] = g
    return v[0]

def grid(S, K, r, q, sig, T, M=2400, NT=2000, american=True):
    # Crank-Nicolson in x = ln S (two implicit first steps), Brennan-Schwartz for the max
    dx, dt = 3.0 / M, T / NT; x0 = log(S) - 1.5
    Sx = [exp(x0 + i * dx) for i in range(M + 1)]
    g = [max(K - s, 0.0) for s in Sx]; v = g[:]
    nu = r - q - 0.5 * sig * sig
    al = 0.5 * sig * sig / dx / dx - 0.5 * nu / dx
    ga = 0.5 * sig * sig / dx / dx + 0.5 * nu / dx
    be = -sig * sig / dx / dx - r
    for k in range(1, NT + 1):
        th = 1.0 if k <= 2 else 0.5; tau = k * dt
        A, B, C = -th * dt * al, 1 - th * dt * be, -th * dt * ga
        R = [0.0] * (M + 1)
        for i in range(1, M):
            R[i] = v[i] + (1 - th) * dt * (al * v[i - 1] + be * v[i] + ga * v[i + 1])
        lo = g[0] if american else K * exp(-r * tau) - Sx[0] * exp(-q * tau)
        Bp, Rp = [0.0] * (M + 1), [0.0] * (M + 1)
        Bp[M - 1], Rp[M - 1] = B, R[M - 1]
        for i in range(M - 2, 0, -1):
            f = C / Bp[i + 1]; Bp[i] = B - f * A; Rp[i] = R[i] - f * Rp[i + 1]
        new = [0.0] * (M + 1); new[0] = lo
        for i in range(1, M):
            new[i] = (Rp[i] - A * new[i - 1]) / Bp[i]
            if american and g[i] > new[i]: new[i] = g[i]
        v = new
    return v[M // 2]

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
N = 2000
ce, pe = bs(S, K, r, q, sig, T)
PA, PEt = tree(S, K, r, q, sig, T, N), tree(S, K, r, q, sig, T, N, rule="never")
CA, CEt = tree(S, K, r, q, sig, T, N, call=True), tree(S, K, r, q, sig, T, N, call=True, rule="never")
PAg, PEg = grid(S, K, r, q, sig, T), grid(S, K, r, q, sig, T, american=False)
PA1 = tree(S, K, r, q, sig, T, 1000); PE1 = tree(S, K, r, q, sig, T, 1000, rule="never")
rows = [("European put, closed form", pe), ("European call, closed form", ce),
        ("1 American put, tree 2000", PA), ("  European put, same tree", PEt),
        ("  limit, 2 x tree 2000 - tree 1000", 2 * PA - PA1), ("  same for the European", 2 * PEt - PE1),
        ("2 American put, grid", PAg), ("  European put, same grid", PEg),
        ("premium, tree 2000 - closed form", PA - pe), ("premium, like for like on tree", PA - PEt),
        ("premium, like for like on grid", PAg - PEg),
        ("American call, tree 2000", CA), ("  European call, same tree", CEt),
        ("  call difference x 1e6", (CA - CEt) * 1e6)]
lo, hi = S * exp(-q * T) - K, S - K * exp(-r * T)
rows += [("parity lower  S e^-qT - K", lo), ("  C_A - P_A", CA - PA), ("parity upper  S - K e^-rT", hi),
         ("  European C - P", ce - pe), ("premium cap  K(1 - e^-rT)", K * (1 - exp(-r * T)))]
# two-step tree by hand
dt = T / 2; u = exp(sig * sqrt(dt)); d = 1 / u; p = (exp((r - q) * dt) - d) / (u - d); D = exp(-r * dt)
Sd, Sdd = S * d, S * d * d
hold_d = D * (1 - p) * (K - Sdd)             # after a rise, every later node pays nothing
rows += [("2-step: u", u), ("2-step: p", p), ("2-step: one-step discount", D), ("2-step: Acme after a fall", Sd),
         ("2-step: after two falls", Sdd), ("2-step: payoff after two falls", K - Sdd), ("2-step: hold after a fall", hold_d),
         ("2-step: exercise after a fall", K - Sd), ("2-step: rule 'never'", D * (1 - p) * hold_d),
         ("2-step: rule 'sell after a fall'", D * (1 - p) * (K - Sd)), ("2-step: tree with max", tree(S, K, r, q, sig, T, 2))]
for name, val in rows: print(f"{name:<34} {val:>12.6f}")
print("stopping rules on the 2000-step tree: exercise first time Acme <= L")
best_rule = 0.0
for L in (70.0, 75.0, 80.0, 82.0, 85.0, 90.0, 99.99):
    val = tree(S, K, r, q, sig, T, N, rule="level", level=L); best_rule = max(best_rule, val)
    print(f"  L = {L:6.2f}   {val:10.6f}")
print("convergence: American put, European put, gap to closed form")
steps = (50, 100, 200, 500, 1000, 2000)
am = [tree(S, K, r, q, sig, T, n) for n in steps[:-2]] + [PA1, PA]
for n, a_ in zip(steps, am):
    e_ = tree(S, K, r, q, sig, T, n, rule="never")
    print(f"  N = {n:5d}   {a_:10.6f}   {e_:10.6f}   {e_ - pe:+.6f}")
tries = [("try r = 0: American", tree(S, K, 0.0, q, sig, T, 500)), ("try r = 0: European", tree(S, K, 0.0, q, sig, T, 500, rule="never")),
         ("try r = 10%: premium", tree(S, K, 0.10, q, sig, T, 500) - tree(S, K, 0.10, q, sig, T, 500, rule="never")),
         ("try q = 0: American put", tree(S, K, r, 0.0, sig, T, 500)),
         ("try sigma = 40%: premium", tree(S, K, r, q, 0.4, T, 500) - tree(S, K, r, q, 0.4, T, 500, rule="never"))]
for name, val in tries: print(f"{name:<34} {val:>12.6f}")
assert abs(pe - 6.330080627550) < 1e-9, "own normal CDF reproduces the house put"
assert abs(PA - PAg) < 0.001 and abs(2 * PA - PA1 - PAg) < 2e-4, "tree and grid agree on the American put"
assert abs(PEt - pe) < 0.002 and abs(PEg - pe) < 0.002, "both machines price the European put"
assert best_rule < PA, "no fixed level beats the best stopping rule"
assert lo < CA - PA < hi and CA - PA < ce - pe, "American parity band, below European parity"
assert all(a2 > a1 for a1, a2 in zip(am, am[1:])), "the tree price climbs as steps grow"
assert abs(tries[0][1] - tries[1][1]) < 1e-9, "no rate, no reason to sell early"
print("ALL CHECKS PASS")
