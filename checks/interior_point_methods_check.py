# Interior point methods -- the check behind the card.  Standard library only.
# Three pumps feed a town.  MINIMISE the power f0(x) = sum a_i x_i^2 (kW) over the flows x (L/s),
# subject to total flow h(x) = x1 + x2 + x3 - 150 = 0, head at the hill tank between 35 and 45 m,
# and every flow at least 0.  The five limits are written f_i(x) <= 0; slack_i = -f_i(x).
# Road 1: the barrier method, Newton centring for t = 1, 10, 100, ... (the central path).
# Road 2: the dual bound q(lambda, nu), from the Lagrangian minimised in closed form.
# Road 3: the KKT conditions solved for every one of the 32 choices of binding limits.
from math import log, ceil, log10
A, K, D, LO, HI = [0.02, 0.03, 0.05], [0.1, 0.2, 0.4], 150, 35, 45   # kW/(L/s)^2, m per L/s, L/s, m, m
GS = [K, [-k for k in K], [1, 0, 0], [0, 1, 0], [0, 0, 1]]          # gradient of each slack
M, START, GROW = 5, [40, 50, 60], 10                                  # limits; strictly inside start; t factor
def tot(vals):                          # plain left-to-right sum, as Rust does it
    s = 0.0
    for v in vals:
        s += v
    return s
f0 = lambda x: tot(a * v * v for a, v in zip(A, x))
head = lambda x: tot(k * v for k, v in zip(K, x))
slacks = lambda x, lo=LO, hi=HI: [head(x) - lo, hi - head(x)] + list(x)
f4 = lambda v: ", ".join(f"{u:.4f}".replace("-0.0000", "0.0000") for u in v)

def gauss(Mx, r):                        # solve Mx z = r by elimination with row swaps
    n = len(r)
    Mx = [list(row) + [v] for row, v in zip(Mx, r)]
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(Mx[i][c]))
        if abs(Mx[p][c]) < 1e-12:
            return None
        Mx[c], Mx[p] = Mx[p], Mx[c]
        for i in range(n):
            if i != c:
                m = Mx[i][c] / Mx[c][c]
                Mx[i] = [u - m * v for u, v in zip(Mx[i], Mx[c])]
    return [Mx[i][n] / Mx[i][i] for i in range(n)]

def phi(x, t):                           # t f0 - sum log(slack); None outside the interior
    s = slacks(x)
    return None if min(s) <= 0 else t * f0(x) - tot(log(v) for v in s)

def newton(x, t):                        # the centring step: a KKT-shaped 4 x 4 linear system
    s = slacks(x)
    g = [t * 2 * A[i] * x[i] - tot(GS[j][i] / s[j] for j in range(M)) for i in range(3)]
    H = [[(t * 2 * A[i] if i == l else 0) + tot(GS[j][i] * GS[j][l] / s[j] ** 2 for j in range(M))
          for l in range(3)] + [1] for i in range(3)]
    z = gauss(H + [[1, 1, 1, 0]], [-v for v in g] + [0])
    return z[:3], z[3], -tot(a * b for a, b in zip(g, z[:3]))   # direction d, w = t nu, decrement squared

def centre(x, t):                        # Newton until the predicted drop dec2 / 2 <= 1e-14 max(t, 1)
    for steps in range(100):
        d, w, dec2 = newton(x, t)
        if dec2 / 2 <= 1e-14 * max(t, 1):   # phi's rounding error grows with t
            return x, w / t, steps
        al, p0 = 1.0, phi(x, t)
        while True:
            y = [x[i] + al * d[i] for i in range(3)]
            py = phi(y, t)
            if py is not None and py <= p0 - 0.25 * al * dec2:
                break
            al /= 2
        x = y

def dual(lam, nu):                       # q(lam, nu) = min over x of the Lagrangian, in closed form
    c = [-lam[0] * K[i] + lam[1] * K[i] - lam[2 + i] + nu for i in range(3)]
    return LO * lam[0] - HI * lam[1] - D * nu - tot(c[i] ** 2 / (4 * A[i]) for i in range(3))

print(f"start {f4(START)} L/s: head {head(START):.4f} m, power {f0(START):.4f} kW, slacks {f4(slacks(START))}")
# ---- road 3: KKT by enumeration of binding sets ----
kkt = []
for mask in range(32):
    act = [j for j in range(M) if mask >> j & 1]
    rows = [[2 * A[i] if c == i else 0 for c in range(3)] + [-GS[j][i] for j in act] + [1] for i in range(3)]
    rows += [GS[j][:3] + [0] * (len(act) + 1) for j in act] + [[1, 1, 1] + [0] * (len(act) + 1)]
    rhs = [0, 0, 0] + [[LO, -HI, 0, 0, 0][j] for j in act] + [D]
    z = gauss(rows, rhs)
    if z and min(slacks(z[:3])) > -1e-9 and all(v > -1e-9 for v in z[3:3 + len(act)]):
        kkt.append((act, z))
print(f"road 3, KKT by enumeration: {len(kkt)} of 32 binding sets pass")
act, z = kkt[0]
xs, lam_star, nu_star = z[:3], z[3], z[4]
pstar = f0(xs)
print(f"  binding: limit {act[0] + 1} (head floor); flows {f4(xs)} L/s, lambda {lam_star:.4f} kW per m, nu {nu_star:.4f}")
print(f"  p* = {pstar:.4f} kW, {0.2 * pstar:.4f} pounds per hour at 0.20 pounds per kWh")
assert len(kkt) == 1 and act == [0] and max(abs(v - 50) for v in xs) < 1e-9
d0, _, dr0 = newton(START, 1.0)       # the Newton step's slope and curvature against central differences of phi
pd = lambda e: phi([START[i] + e * d0[i] for i in range(3)], 1.0)
assert abs((pd(1e-3) - pd(-1e-3)) / 2e-3 + dr0) < 1e-5 * dr0 and abs((pd(1e-3) - 2 * pd(0) + pd(-1e-3)) / 1e-6 - dr0) < 1e-5 * dr0
# ---- road 1 and road 2: the central path, with a certificate at every point ----
x, t, eps, total, path = START, 1.0, 1e-4, 0, []
while True:
    x, nu, n = centre(x, t)
    lam = [1 / (t * s) for s in slacks(x)]
    q = dual(lam, nu)
    total += n
    path.append((t, x, nu, lam, q, n))
    print(f"t {t:9.0f}: flows {f4(x)}, head {head(x):.4f} m, power {f0(x):.4f}, bound {q:.4f}, gap {f0(x) - q:.5f} kW, {n} steps")
    assert abs((f0(x) - q) - M / t) < 1e-7 and q <= pstar + 1e-9 <= f0(x) + 2e-9
    if M / t <= eps:
        break
    t *= GROW
rounds = 1 + ceil(log10(M / eps) / log10(GROW))                     # t0 = 1
print(f"rounds {len(path)} (formula 1 + ceil(log(m / (t0 eps)) / log(factor)) = {rounds}), Newton steps {total}")
print("Newton steps per round:", " ".join(str(p[5]) for p in path))
print("power minus p*, kW:", " ".join(f"{f0(p[1]) - pstar:.6f}" for p in path[:5]))
print("ratio of successive errors:", " ".join(f"{(f0(a[1]) - pstar) / (f0(b[1]) - pstar):.4f}" for a, b in zip(path[:4], path[1:5])))
assert len(path) == rounds and max(abs(u - v) for u, v in zip(x, xs)) < 1e-4 and abs(nu - nu_star) < 1e-4
t1, x1, nu1, lam1, q1, _ = path[0]
print(f"at t = 1: slacks {', '.join(f'{v:.6f}' for v in slacks(x1))}")
print(f"at t = 1: lambda {f4(lam1)}; lambda_i * slack_i = {f4([l * s for l, s in zip(lam1, slacks(x1))])}")
print(f"at t = 1: pump A row {2 * A[0] * x1[0]:.6f} - {K[0] * lam1[0]:.6f} + {K[0] * lam1[1]:.6f} - {lam1[2]:.6f} + nu = 0, nu = {nu1:.6f}")
print(f"at t = {t:.0f}: lambda {f4(path[-1][3])}")
assert abs(path[-1][3][0] - lam_star) < 1e-3
# ---- the picture: the central path in the (x1, x2) plane, x3 = 150 - x1 - x2 ----
xa = centre(START, 1e-9)[0]
pts = [xa] + [centre(START, tt)[0] for tt in (0.003, 0.01, 0.03, 0.1, 0.3, 1)]
print("figure, path (x1, x2):", " ".join(f"({p[0]:.2f}, {p[1]:.2f})" for p in pts))
print(f"figure, analytic centre head {head(xa):.4f} m; head-floor line through (44.67, 58) and (59.33, 36); optimum (50, 50)")
# ---- what breaks ----
bad = [70, 50, 30]
print(f"start outside {f4(bad)}: head {head(bad):.4f} m, slack {slacks(bad)[0]:.4f}, barrier {"undefined" if phi(bad, 1) is None else "defined"}")
print(f"window 35 to 35 m: slacks at the best plan {f4(slacks(xs, 35, 35)[:2])}; their sum is 0 for every plan")
d, _, _ = newton(x1, 10.0)
y = [x1[i] + d[i] for i in range(3)]
print(f"full Newton step from x*(1) at t = 10: flows {f4(y)}, head {head(y):.4f} m, barrier {"undefined" if phi(y, 10) is None else "defined"}")
assert head(y) < LO and phi(bad, 1) is None
lam_bad = [1 / s for s in slacks(path[1][1])]
print(f"multipliers without the 1/t at t = 10: head floor {lam_bad[0]:.4f}, bound {dual(lam_bad, path[1][2] * 10):.4f} kW")
print(f"stop at t = 1 and call it best: {f0(x1):.4f} kW, {f0(x1) - pstar:.4f} kW too much")
print("ALL CHECKS PASS")
