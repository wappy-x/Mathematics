# American options on a grid -- the check behind the card.  Standard library only,
# nothing imported that already knows the answer.  Two independent roads reach the
# American put, projected SOR on a grid and a 2000-step tree; a third settles the
# smallest case exactly, by search over the floor patterns.
from math import log, sqrt, exp, erf
K, R, Q, SIG, T = 100.0, 0.05, 0.02, 0.20, 1.0   # Acme: strike, rate, dividend, vol, year
XL, XR = -1.5, 1.5                               # the grid spans ln(S/K), -1.5 to 1.5
def ncdf(x):    return 0.5 * (1.0 + erf(x / sqrt(2.0)))    # bell-curve area left of x
def euro_put(r):                                 # Black-Scholes European put, Acme at 100
    vt = SIG * sqrt(T)
    d1 = (r - Q + 0.5 * SIG * SIG) * T / vt
    return K * exp(-r * T) * ncdf(vt - d1) - K * exp(-Q * T) * ncdf(-d1)
def read_line(S, g, v):
    # Last node on its floor, first node above it, then a sub-grid reading from the
    # free side, where the gap between value and payoff opens like a square.
    k = max(i for i in range(1, len(S) - 1) if g[i] > 0.0 and v[i] <= g[i] + 1e-12)
    y1, y2 = sqrt(v[k + 1] - g[k + 1]), sqrt(v[k + 2] - g[k + 2])
    return S[k], S[k + 1], S[k + 1] - y1 * (S[k + 2] - S[k + 1]) / (y2 - y1)
def layers(M, Nt, om, mode, r=R, tol=1e-11):
    # One implicit layer at a time, from expiry back to today.  mode 'amer' projects
    # onto the floor inside every sweep, 'euro' never does, and 'lift' solves the
    # free equations, lifting onto the floor once, at the layer's end.
    h, dt = (XR - XL) / M, T / Nt
    nu = dt * SIG * SIG / (2.0 * h * h)              # the spreading ratio
    eta = dt * (r - Q - 0.5 * SIG * SIG) / (2.0 * h)  # the sliding ratio
    lo, up, d = nu - eta, nu + eta, 1.0 + 2.0 * nu + r * dt
    S = [K * exp(XL + i * h) for i in range(M + 1)]
    g = [max(K - s, 0.0) for s in S]
    v, sweeps, line = list(g), 0, {}
    for k in range(Nt):
        tau, b, v[M] = (k + 1) * dt, list(v), 0.0
        v[0] = K - S[0] if mode != "euro" else K * exp(-r * tau) - S[0] * exp(-Q * tau)
        while True:
            chg = 0.0
            for i in range(1, M):
                y = (1.0 - om) * v[i] + om * (b[i] + lo * v[i - 1] + up * v[i + 1]) / d
                y = max(y, g[i]) if mode == "amer" else y     # project after relaxing
                chg, v[i] = max(chg, abs(y - v[i])), y
            sweeps += 1
            if chg <= tol: break
        v = [max(v[i], g[i]) for i in range(M + 1)] if mode == "lift" else v
        if mode == "amer" and r == R and (k + 1) * 12 % Nt == 0: line[(k + 1) * 12 // Nt] = read_line(S, g, v)
    return S, g, v, sweeps, line, (lo + up) / d, (abs(1.0 - om) + om * up / d) / (1.0 - om * lo / d)
def tree(n, american, r=R):
    # Cox-Ross-Rubinstein: up or down each step, roll the payoff back, and for the
    # American put take the better of exercising and holding at every node.
    dt, u = T / n, exp(SIG * sqrt(T / n))
    dn, disc = 1.0 / u, exp(-r * dt)
    p = (exp((r - Q) * dt) - dn) / (u - dn)
    pu, pd = [1.0] * (n + 1), [1.0] * (n + 1)
    for i in range(1, n + 1):
        pu[i], pd[i] = pu[i - 1] * u, pd[i - 1] * dn
    v = [max(K - K * pu[n - j] * pd[j], 0.0) for j in range(n + 1)]
    for i in range(n - 1, -1, -1):
        v = [disc * (p * v[j] + (1.0 - p) * v[j + 1]) for j in range(i + 1)]
        if american: v = [max(v[j], K - K * pu[i - j] * pd[j]) for j in range(i + 1)]
    return v[0]
def toy_exact(al, ga, b, f):
    # Two coupled values, settled exactly: try all four patterns of 'on the floor /
    # above it', keep whichever meets all three conditions at once.
    d = 1 + al + ga
    for num, den in (([d * b[0] + ga * b[1], al * b[0] + d * b[1]], d * d - al * ga),
                     ([f[0] * d, b[1] + al * f[0]], d), ([b[0] + ga * f[1], f[1] * d], d),
                     ([f[0], f[1]], 1)):
        gap = [num[0] - f[0] * den, num[1] - f[1] * den]
        w = [d * num[0] - ga * num[1] - b[0] * den, d * num[1] - al * num[0] - b[1] * den]
        if min(gap + w) >= 0 and gap[0] * w[0] == 0 and gap[1] * w[1] == 0:
            return [x / den for x in num], [x / den for x in w]   # the one true pattern
def toy_sweep(x, b, f, al, ga, om):              # one projected sweep, lower neighbour first
    d, new = 1 + al + ga, list(x)
    for i in (0, 1):
        t = (b[i] + al * (new[i - 1] if i else 0.0) + ga * (x[i + 1] if i < 1 else 0.0)) / d
        new[i] = max(f[i], (1.0 - om) * x[i] + om * t)
    return new
BB, FF = [0, 3], [1, 0]                          # the right-hand side, and the two floors
free = [(3 * BB[0] + BB[1]) / 8.0, (BB[0] + 3 * BB[1]) / 8.0]
lift2 = [max(free[0], float(FF[0])), max(free[1], float(FF[1]))]
lift_w = [3.0 * lift2[0] - lift2[1] - BB[0], 3.0 * lift2[1] - lift2[0] - BB[1]]
lcp, lcp_w = toy_exact(1, 1, BB, FF)
tx = [float(FF[0]), float(FF[1])]
for _ in range(40):
    tx = toy_sweep(tx, BB, FF, 1, 1, 1.1)
bad = (1.0 - 1.5) * 2.0 + 1.5 * max(1.0, 0.0)    # projecting before relaxing, one value
good = toy_sweep([2.0, 0.0], [0, 0], [1, 0], 0.0, 0.0, 1.5)[0]   # the rule, from the sweep
cyc, cycles = 0.0, []                            # omega = 2, one value, floor 0, b = 1
for _ in range(4):
    cycles.append(cyc := toy_sweep([cyc, 0.0], [1, 0], [0, 0], 0.0, 0.0, 2.0)[0])
M, NT, OM = 240, 120, 1.1
S, g, va, swa, line, qm, qs = layers(M, NT, OM, "amer")
ve, vl = layers(M, NT, OM, "euro")[2], layers(M, NT, OM, "lift")[2]
va0, ve0 = layers(M, NT, OM, "amer", 0.0)[2], layers(M, NT, OM, "euro", 0.0)[2]
i0, nu = M // 2, R - Q - 0.5 * SIG * SIG         # index M/2 is ln(S/K) = 0, Acme at 100
pw = (-nu - sqrt(nu * nu + 2.0 * SIG * SIG * R)) / (SIG * SIG)
perp = K * pw / (pw - 1.0)                       # the never-expiring put's line
lad = []
for (m, n) in ((60, 30), (120, 60), (240, 120), (480, 240)):
    Sx, gx, vx, swx = layers(m, n, OM, "amer")[:4]
    lad.append((m, n, swx, vx[m // 2], layers(m, n, OM, "euro")[2][m // 2], read_line(Sx, gx, vx)[2]))
print("the smallest one: two coupled values, floors 1 and 0")
for name, pair in (("free solve, no floor", free), ("free solve, then lifted to the floor", lift2),
                   ("  the lifted pair's two slacks", lift_w), ("exact search over patterns", lcp),
                   ("  its two slacks", lcp_w), ("projected SOR from the floor, 40 sweeps", tx)):
    print(f"  {name:<40}{pair[0]:>11.6f}{pair[1]:>11.6f}")
print(f"  {'projecting before relaxing, one value':<40}{bad:>11.6f}  (correct {good:.6f})")
print(f"  {'omega = 2 from 0, four sweeps':<40}" + "".join(f"{c:>7.3f}" for c in cycles))
print(f"\nAcme American put, grid {M} x {NT}, omega {OM:.3f}, {swa} sweeps in all")
for name, val in (("contraction of the all-at-once map", qm),
                  ("contraction bound on one projected sweep", qs),
                  ("American put at S = 100", va[i0]), ("European, same grid, no floor", ve[i0]),
                  ("European put, Black-Scholes", euro_put(R)),
                  ("early-exercise premium, same grid", va[i0] - ve[i0]),
                  ("floor lifted once at each layer's end", vl[i0]),
                  ("with r = 0: American on this grid", va0[i0]),
                  ("with r = 0: European on this grid", ve0[i0]),
                  ("line today, last node on its floor", line[12][0]),
                  ("line today, first node above it", line[12][1]),
                  ("line today, square-root reading", line[12][2]), ("perpetual line, exact", perp)):
    print(f"  {name:<42}{val:>13.6f}")
print("\nrefining the grid, with the tree as the second road")
print(f"  {'grid':<12}{'sweeps':>8}{'American':>11}{'European':>11}{'premium':>10}{'line today':>12}")
for (m, n, sw, av, ev, ln) in lad:
    print(f"  {f'{m} x {n}':<12}{sw:>8}{av:>11.6f}{ev:>11.6f}{av - ev:>10.6f}{ln:>12.4f}")
for n, a, e in ((n, tree(n, True), tree(n, False)) for n in (2000, 4000)):
    print(f"  {f'tree {n}':<12}{'':>8}{a:>11.6f}{e:>11.6f}{a - e:>10.6f}")
print(f"\nthe exercise line through the year, grid {M} x {NT}")
print(f"  {'months left':<12}" + "".join(f"{m:>8}" for m in (12, 9, 6, 3, 1, 0)))
print(f"  {'exercise line':<12}" + "".join(f"{line[m][2]:>8.2f}" for m in (12, 9, 6, 3, 1)) + f"{K:>8.2f}")
print(f"\ntoday's put against its payoff, grid {M} x {NT}")
for name, series in (("Acme price", S), ("put value", va), ("payoff", g)):
    print(f"  {name:<12}" + "".join(f"{series[i]:>8.2f}" for i in range(i0 - 28, i0 + 5, 4)))
assert abs(lad[3][3] - tree(2000, True)) < 0.01 and abs(lad[3][4] - euro_put(R)) < 0.01
assert va[i0] - ve[i0] > 0.30                         # the floor is worth real money
assert abs(va0[i0] - ve0[i0]) < 1e-12                 # no interest, so the floor never binds
assert max(abs(tx[0] - lcp[0]), abs(tx[1] - lcp[1])) < 1e-12  # sweeps vs the exact search
assert min(lift_w) < 0.0 and min(lcp_w) >= 0.0        # lifting is no solution; the LCP one is
assert perp < line[12][0] and line[12][1] < K and all(abs(l[5] - lad[3][5]) < 0.5 for l in lad)
ic = S.index(line[12][0]); assert va[ic] == g[ic] and va[ic + 1] - g[ic + 1] > 1e-6  # contact, free
assert all(line[m][2] < line[m - 1][2] for m in range(2, 13))  # the line rises toward expiry
assert bad < FF[0] <= good and max(cycles) - min(cycles) > 1.0
print("ALL CHECKS PASS")
