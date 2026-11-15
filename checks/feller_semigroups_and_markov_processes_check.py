# Feller semigroups -- the check behind the card.  Standard library only.
# Share price X_t = x + mu t + sigma W_t (pounds, years); payoff f: a 90/100/110 butterfly.
# Generator A f = mu f' + (1/2) sigma^2 f''; Feller semigroup P_t f(x) = E_x[f(X_t)].
# Roads: closed form; a price grid (a Markov chain) by uniformization and by the resolvent
# product; Monte Carlo along random paths (SplitMix64, seed 20261115).
import math
MU, SIG, X0, T, WINGS = 5.0, 20.0, 100.0, 1.0, ((90.0, 1.0), (100.0, -2.0), (110.0, 1.0))
phi = lambda z: math.exp(-0.5 * z * z) / math.sqrt(2 * math.pi)
tent = lambda y: max(0.0, 10.0 - abs(y - 100.0))   # the butterfly payoff, pounds
def close(a, b, tol): assert abs(a - b) <= tol, (a, b)
def ncdf(z):                      # 1/2 + phi(z) (z + z^3/3 + z^5/(3*5) + ...)
    if abs(z) > 9: return 1.0 if z > 0 else 0.0
    term, s, n = z, z, 0
    while abs(term) > 1e-17 * abs(s) or n < 5:
        term, n = term * z * z / (2 * n + 3), n + 1
        s += term
    return 0.5 + phi(z) * s
def u(t, x, mu=MU, sig=SIG):      # P_t f(x): three normal-model calls, weights 1, -2, 1
    if t == 0: return tent(x)
    m, s = x + mu * t, sig * math.sqrt(t)
    return sum(c * ((m - k) * ncdf((m - k) / s) + s * phi((m - k) / s)) for k, c in WINGS)
close(ncdf(0.75), 0.5 * (1 + math.erf(0.75 / math.sqrt(2))), 1e-15); exact = u(T, X0)   # erf: library check only
print(f"read, generator 5 f' + 200 f'': drift {MU:.6f} pounds/yr, sigma = sqrt(2 x 200) = {math.sqrt(400):.6f}")
print("closed form, calls at 90, 100, 110 (mean 105, spread 20): " + ", ".join(f"{(105 - k) * ncdf((105 - k) / 20) + 20 * phi((105 - k) / 20):.6f}" for k, _ in WINGS))
print(f"closed form, P_1 f(100) = {exact:.6f} pounds, discounted at 5% {math.exp(-0.05) * exact:.6f}")
# 1. The finite rehearsal: a Markov chain on prices 0, dl, ..., 200, walls at both ends.
def rates(dl, mu, s2):
    n = int(round(200 / dl)) + 1
    up, dn = [s2 / (2 * dl * dl) + mu / (2 * dl)] * n, [s2 / (2 * dl * dl) - mu / (2 * dl)] * n
    up[-1], dn[0] = 0.0, 0.0
    return n, up, dn
def qmul(up, dn, v, r=0.0):       # (Q - r I) v for the tridiagonal rate matrix Q
    n = len(v)
    return [(up[i] * (v[i + 1] - v[i]) if i < n - 1 else 0.0) + (dn[i] * (v[i - 1] - v[i]) if i else 0.0) - r * v[i] for i in range(n)]
def unif(dl, f, t, r=0.0):        # e^{t(Q - rI)} f = sum over k of Poisson(lam t; k) K^k f
    n, up, dn = rates(dl, MU, SIG ** 2)
    lam = max(up[i] + dn[i] for i in range(n)) + r
    v, out, lw, k = f[:], [0.0] * n, -lam * t, 0
    while k < lam * t + 12 * math.sqrt(lam * t) + 30:
        out = [o + math.exp(lw) * a for o, a in zip(out, v)]
        v = [a + b / lam for a, b in zip(v, qmul(up, dn, v, r))]
        k += 1
        lw += math.log(lam * t) - math.log(k)
    return out
print("read, grid step, up rate, down rate, drift from the row, variance rate from the row")
for dl in (5.0, 2.5, 1.25, 0.625):
    n, up, dn = rates(dl, MU, SIG ** 2)
    a, b = (up[n // 2] - dn[n // 2]) * dl, (up[n // 2] + dn[n // 2]) * dl * dl
    close(a, MU, 1e-9); close(b, SIG ** 2, 1e-9)
    print(f"read, {dl:.3f}, {up[0]:.6f}, {dn[-1]:.6f}, {a:.6f}, {b:.6f}")
print("read, h, (E X_h - x)/h, E (X_h - x)^2 / h, on the grid from 100; closed form 400 + 25 h")
for h in (0.1, 0.01, 0.001):
    m1 = unif(1.25, [i * 1.25 - 100 for i in range(161)], h)[80] / h
    m2 = unif(1.25, [(i * 1.25 - 100) ** 2 for i in range(161)], h)[80] / h
    close(m1, MU, 1e-9); close(m2, 400 + 25 * h, 1e-8)
    print(f"read, {h}, {m1:.6f}, {m2:.6f}, {400 + 25 * h:.6f}")
print("grid, cells N, step, P_1 f(100), error, error ratio")
errs, gs = [], {}
for dl in (5.0, 2.5, 1.25, 0.625):
    n = int(round(200 / dl)) + 1
    gs[dl] = g = unif(dl, [tent(i * dl) for i in range(n)], T)[n // 2]
    errs.append(g - exact)
    print(f"grid, {n - 1}, {dl:.3f}, {g:.6f}, {g - exact:.6f}, " + (f"{errs[-2] / errs[-1]:.3f}" if len(errs) > 1 else "-"))
assert 3.5 < errs[2] / errs[3] < 4.5 and abs(errs[3]) < 0.001
print("chart, log10 N, " + ", ".join(f"{math.log10(200 / d):.3f}" for d in gs))
print("chart, log10 abs error, " + ", ".join(f"{math.log10(abs(e)):.3f}" for e in errs))
# 2. Feller properties of the 41-state matrix P_1 (step 5).
n = 41; cols = [unif(5.0, [1.0 if i == j else 0.0 for i in range(n)], T) for j in range(n)]
neg = sum(1 for c in cols for a in c if a < 0)
rowdev = max(abs(sum(cols[j][i] for j in range(n)) - 1) for i in range(n))
f5 = [tent(5.0 * i) for i in range(n)]
p1 = unif(5.0, f5, T)
semi = max(abs(a - b) for a, b in zip(unif(5.0, unif(5.0, f5, 0.5), 0.5), p1))
assert neg == 0 and rowdev < 1e-12 and max(p1) <= 10 and semi < 1e-12
print(f"feller, step 5: negative entries {neg}, rows sum to 1: {'yes' if rowdev < 1e-12 else 'no'}, P_0.5 P_0.5 f = P_1 f: {'yes' if semi < 1e-12 else 'no'}, largest P_1 f = {max(p1):.6f}")
kill = unif(5.0, [1.0] * n, T, r=0.05)
close(kill[20], math.exp(-0.05), 1e-12)
print(f"killed, rate 0.05: P_1 1 = {kill[20]:.6f}, e^-0.05 = {math.exp(-0.05):.6f}")
# 3. Hille-Yosida's road: (I - Q/n)^(-n) f, by n tridiagonal solves (step 1.25).
def resolvent_power(dl, f, t, steps):
    (n, up, dn), h, v = rates(dl, MU, SIG ** 2), t / steps, f[:]
    for _ in range(steps):
        cp, dp = [0.0] * n, [0.0] * n
        for i in range(n):
            a = -h * dn[i]
            den = 1 + h * (up[i] + dn[i]) - (a * cp[i - 1] if i else 0.0)
            cp[i], dp[i] = -h * up[i] / den, (v[i] - (a * dp[i - 1] if i else 0.0)) / den
        for i in range(n - 1, -1, -1):
            v[i] = dp[i] - (cp[i] * v[i + 1] if i < n - 1 else 0.0)
    return v
print("resolvent, n, (I - Q/n)^-n f at 100, gap to uniformization, n x gap")
for st in (10, 100, 1000):
    r = resolvent_power(1.25, [tent(i * 1.25) for i in range(161)], T, st)[80]
    print(f"resolvent, {st}, {r:.6f}, {r - gs[1.25]:.6f}, {st * (r - gs[1.25]):.4f}")
close(r, gs[1.25], 1e-3)
# 4. Averages along random paths: four quarterly steps, SplitMix64, Box-Muller.
state = 20261115
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
paths, s1, s2 = 40000, 0.0, 0.0
for _ in range(paths):
    x = X0
    for _ in range(2):             # each pair of normals moves the price two quarters
        rr, b = math.sqrt(-2 * math.log(1.0 - rnd())), 2 * math.pi * rnd()
        x += 2 * MU * 0.25 + SIG * 0.5 * (rr * math.cos(b) + rr * math.sin(b))
    s1, s2 = s1 + tent(x), s2 + tent(x) ** 2
mc, se = s1 / paths, math.sqrt((s2 / paths - (s1 / paths) ** 2) / paths)
assert abs(mc - exact) < 4 * se
print(f"paths, {paths} paths of 4 quarterly steps: average payoff {mc:.6f}, standard error {se:.6f}")
# 5. Strong continuity in the sup norm: the butterfly (in C_0) against a digital (a jump).
print("continuity, h, sup |P_h f - f|, divided by sqrt h, digital gap at the jump, (P_h f - f)/h at 100")
for h in (0.1, 0.01, 0.001):
    sup = max(abs(u(h, 80 + 0.01 * i) - tent(80 + 0.01 * i)) for i in range(4001))
    dig = 10 * ncdf(MU * math.sqrt(h) / SIG)
    assert dig > 5 and sup < 16 * math.sqrt(h)
    print(f"continuity, {h}, {sup:.4f}, {sup / math.sqrt(h):.4f}, {dig:.4f}, {(u(h, X0) - 10) / h:.4f}")
close(sup / math.sqrt(h), 20 * math.sqrt(2 / math.pi), 0.02)
# 6. The backward equation du/dt = A u at t = 1, x = 100, by finite differences.
dt, dx = 1e-4, 1e-2; ut = (u(T + dt, X0) - u(T - dt, X0)) / (2 * dt)
au = MU * (u(T, X0 + dx) - u(T, X0 - dx)) / (2 * dx) + 200 * (u(T, X0 + dx) - 2 * exact + u(T, X0 - dx)) / dx ** 2
close(ut, au, 1e-5)
print(f"backward, du/dt = {ut:.6f}, A u = 5 u_x + 200 u_xx = {au:.6f}")
# 7. What breaks, and the chart.
print(f"breaks, sigma read as sqrt 200 = {math.sqrt(200):.6f}: P_1 f(100) = {u(T, X0, sig=math.sqrt(200)):.6f}")
print(f"breaks, drift dropped (the bar's heat flow): P_1 f(100) = {u(T, X0, mu=0.0):.6f}")
print("breaks, curvature sign flipped, step, zigzag growth rate per year, 800/step^2")
for dl in (5.0, 2.5, 1.25, 0.625):
    n, up, dn = rates(dl, MU, -SIG ** 2)
    gr = qmul(up, dn, [(-1.0) ** i for i in range(n)])[n // 2] / (-1.0) ** (n // 2)
    close(gr, 800 / dl ** 2, 1e-9)
    print(f"breaks, {dl:.3f}, {gr:.6f}, {800 / dl ** 2:.6f}")
xs = [70 + 5 * i for i in range(13)]
print("chart, x, " + ", ".join(str(x) for x in xs))
for t in (0.0, 0.25, 1.0):
    print(f"chart, t = {t:.2f}, " + ", ".join(f"{u(t, x):.2f}" for x in xs))
print("ALL CHECKS PASS")
