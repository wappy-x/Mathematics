# Weak solutions -- the check behind the card.  Standard library only.
# A wall: 0.1 m of mineral wool (k = 0.035 W/(m K)) on the room side, then
# 0.1 m of brick (k = 0.77).  Faces held at 20 C and 0 C.  Steady state:
# -(k u')' = 0.  The conductivity jumps, so u'' does not exist at the joint.
# Roads to the joint temperature: resistances in series (closed form); hat
# functions solved by the Thomas algorithm (Galerkin); a smooth probe that
# straddles the joint (Simpson quadrature, then a secant step).
import math

K1, K2, L1, L2, TIN, TOUT = 0.035, 0.77, 0.1, 0.1, 20.0, 0.0
L, DT = L1 + L2, TIN - TOUT

def kbar(a, b):                         # mean conductivity over [a, b]
    wool = max(0.0, min(b, L1) - a)
    return (K1 * wool + K2 * (b - a - wool)) / (b - a)

def galerkin(n):                        # hats on n elements; returns nodes, flux, energy
    h = L / n
    ks = [kbar(e * h, (e + 1) * h) for e in range(n)]
    m = n - 1                           # inside nodes 1..n-1
    diag = [(ks[i] + ks[i + 1]) / h for i in range(m)]
    off = [-ks[i + 1] / h for i in range(m - 1)]
    rhs = [0.0] * m
    rhs[0] += ks[0] / h * TIN
    rhs[-1] += ks[-1] / h * TOUT
    c, d = [0.0] * m, [0.0] * m         # Thomas algorithm, written out
    for i in range(m):
        den = diag[i] - (off[i - 1] * c[i - 1] if i else 0.0)
        c[i] = off[i] / den if i < m - 1 else 0.0
        d[i] = (rhs[i] - (off[i - 1] * d[i - 1] if i else 0.0)) / den
    u = [0.0] * m
    for i in range(m - 1, -1, -1):
        u[i] = d[i] - (c[i] * u[i + 1] if i < m - 1 else 0.0)
    u = [TIN] + u + [TOUT]
    flux = -ks[0] * (u[1] - u[0]) / h
    energy = sum(ks[e] * (u[e + 1] - u[e]) ** 2 / h for e in range(n))
    series = DT / sum(h / ke for ke in ks)          # second road to the flux
    return u, flux, energy, series

def simpson(f, a, b, n=400):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3

def dbump(x, centre, r):                # slope of the smooth probe exp(-1/(1-t^2))
    t = (x - centre) / r
    if abs(t) >= 1:
        return 0.0
    return math.exp(-1 / (1 - t * t)) * (-2 * t / (1 - t * t) ** 2) / r

def residual(tj, centre, r):            # integral of k u' v' for the profile with joint tj
    s1, s2 = (tj - TIN) / L1, (TOUT - tj) / L2
    lo, hi = max(0.0, centre - r), min(L, centre + r)
    left = simpson(lambda x: K1 * s1 * dbump(x, centre, r), lo, L1) if lo < L1 else 0.0
    right = simpson(lambda x: K2 * s2 * dbump(x, centre, r), max(lo, L1), hi) if hi > L1 else 0.0
    return left + right

def clean(x):                           # print a rounding-level number as 0
    return 0.0 if abs(x) < 5e-7 else x

R1, R2 = L1 / K1, L2 / K2
q = DT / (R1 + R2)
tj = TIN - q * R1
s1, s2 = -q / K1, -q / K2
energy = K1 * s1 ** 2 * L1 + K2 * s2 ** 2 * L2
print(f"road 1, resistances: wool {R1:.4f}, brick {R2:.4f} m^2 K/W; flux {q:.4f} W/m^2")
print(f"joint temperature {tj:.4f} C; slopes {s1:.2f} and {s2:.2f} K/m; energy a(u,u) {energy:.4f}")
print(f"flux times temperature drop {q * DT:.4f}; heat flux each side {-K1 * s1:.4f} and {-K2 * s2:.4f}")
u2 = galerkin(2)[0]
u4, f4 = galerkin(4)[:2]
print(f"road 2, Galerkin with a node on the joint: N=2 joint {u2[1]:.6f}, N=4 joint {u4[2]:.6f} C")
print("N=4 nodes " + ", ".join(f"{v:.4f}" for v in u4) + f"; flux {f4:.4f}")
mid = (TIN + TOUT) / 2                  # the straight line's joint temperature
r0, r1 = residual(mid, L1, 0.05), residual(TOUT, L1, 0.05)
tp = mid - r0 * (TOUT - mid) / (r1 - r0)            # one secant step: the residual is linear
print(f"road 3, probe on the joint (radius 0.05 m): residual {r0:.4f} at joint {mid:.0f} C, {r1:.4f} at {TOUT:.0f} C")
print(f"the probe's zero: joint {tp:.6f} C; residual for the true profile {clean(residual(tj, L1, 0.05)):.6f}")
print(f"probe inside the wool only (centre 0.05, radius 0.04): residual for the straight line "
      f"{clean(residual(mid, 0.05, 0.04)):.6f}")
print("profile at x = 0, 0.025 .. 0.2 m: weak solution, then straight line")
xs = [i * 0.025 for i in range(9)]
prof = [TIN + s1 * x if x <= L1 else tj + s2 * (x - L1) for x in xs]
print("chart," + ",".join(f"{clean(v):.2f}" for v in prof))
print("chart," + ",".join(f"{TIN - DT * x / L:.2f}" for x in xs))
print("mesh cutting the joint: N, flux, series flux, energy error, error x sqrt(N)")
errs = []
for n in [3, 5, 9, 17, 33, 65, 129]:
    _, fl, en, se = galerkin(n)
    err = math.sqrt(en - energy)
    errs.append((n, err, DT * (fl - q), fl, se))
    print(f"N={n:3d}  {fl:.4f}  {se:.4f}  {err:.4f}  {err * math.sqrt(n):.4f}")
def smooth(x, eps):                     # the C^2 profile itself: slope blended by 3t^2 - 2t^3
    t = min(max((x - L1 + eps) / (2 * eps), 0.0), 1.0)
    return TIN + s1 * min(x, L1 - eps) + 2 * eps * (s1 * t + (s2 - s1) * (t * t * t - t * t * t * t / 2)) + s2 * max(0.0, x - L1 - eps)
def cells(eps, n=2000):                 # second road: k (temperature step)^2 / width, cell by cell
    segs = [(0.0, L1 - eps, K1), (L1 - eps, L1, K1), (L1, L1 + eps, K2), (L1 + eps, L, K2)]
    return sum(kk * (smooth(a + (i + 1) * (b - a) / n, eps) - smooth(a + i * (b - a) / n, eps)) ** 2 * n / (b - a)
               for a, b, kk in segs for i in range(n))
print("smooth profiles closing on the corner: reach, energy excess (Simpson, cells), largest bend K/m^2")
excess, steps = [], []
for eps in [0.01, 0.001, 0.0001]:
    ds = s2 - s1
    blend = lambda t, k: k * (s1 + ds * (3 * t * t - 2 * t ** 3)) ** 2
    en = K1 * s1 ** 2 * (L1 - eps) + K2 * s2 ** 2 * (L2 - eps)
    en += 2 * eps * (simpson(lambda t: blend(t, K1), 0, 0.5) + simpson(lambda t: blend(t, K2), 0.5, 1))
    excess.append(en - energy)
    steps.append(cells(eps) - energy)
    print(f"reach {eps:.4f} m  excess {en - energy:.4f}, {steps[-1]:.4f}  bend {0.75 * ds / eps:.0f}")
cc, CC = min(K1, K2), max(K1, K2)
wnorm = math.sqrt((s1 + DT / L) ** 2 * L1 + (s2 + DT / L) ** 2 * L2)
bound = CC / cc * math.sqrt((DT / L) ** 2 * L)
print(f"Lax-Milgram: c = {cc:.3f}, C = {CC:.3f}; correction size {wnorm:.4f}, guaranteed below {bound:.4f}")
print(f"mistake 1, straight line: energy {(K1 + K2) * (DT / L) ** 2 * L1:.4f}; flux wool "
      f"{K1 * DT / L:.4f}, brick {K2 * DT / L:.4f}")
print(f"mistake 2, average conductivity {(K1 + K2) / 2:.4f}: flux {(K1 + K2) / 2 * DT / L:.4f}")
h4 = L / 4                              # mistake 3: both faces free, N = 4
k4 = [kbar(e * h4, (e + 1) * h4) for e in range(4)]
A = [[0.0] * 5 for _ in range(5)]
for e in range(4):
    for i, j, sgn in [(e, e, 1), (e + 1, e + 1, 1), (e, e + 1, -1), (e + 1, e, -1)]:
        A[i][j] += sgn * k4[e] / h4
for p in range(4):                      # elimination, no row swaps
    for i in range(p + 1, 5):
        f = A[i][p] / A[p][p]
        A[i] = [a - f * b for a, b in zip(A[i], A[p])]
piv = ", ".join(f"{A[i][i]:.4f}" for i in range(4))
print(f"mistake 3, both faces given a flux (N=4): pivots {piv}, last pivot {clean(A[4][4]):.4f}")
assert abs(u4[2] - tj) < 1e-9 and abs(f4 - q) < 1e-9          # Galerkin against resistances
assert abs(tp - tj) < 1e-6                                     # probe against resistances
assert abs(r0 - math.exp(-1) * (K2 - K1) * DT / L) < 1e-6      # quadrature against exact
assert all(abs(fl - se) < 1e-9 for _, _, _, fl, se in errs)    # Thomas against series formula
assert all(abs(e * e - d) < 1e-9 for _, e, d, _, _ in errs)      # energy gap = drop x flux gap
assert abs(errs[-1][1] * math.sqrt(129) / (errs[-2][1] * math.sqrt(65)) - 1) < 0.05  # rate 1/2
assert excess[0] > excess[1] > excess[2] > 0                   # smooth profiles cost more
assert all(abs(e - m) < 1e-5 * e for e, m in zip(excess, steps))  # Simpson on the slope against the cells
assert all(abs(smooth(L, e) - TOUT) < 1e-9 for e in [0.01, 0.001, 0.0001])  # the blend keeps the 20 K drop
assert abs(q * DT - energy) < 1e-9                             # energy balance: flux x drop
assert wnorm < bound                                           # Lax-Milgram's ceiling
assert abs(A[4][4]) < 1e-9                                     # both faces free: singular
print("ALL CHECKS PASS")
