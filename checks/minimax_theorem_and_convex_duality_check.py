# Minimax: the penalty kick as a 2 by 2 game, then the goal mouth as a line.
# Standard library only. The simplex solver and every certificate are written out.
from fractions import Fraction as Fr

def simplex(A):
    """Keeper's LP: maximise sum(z) with A z <= 1, z >= 0 (Bland's rule).
    Returns value V, kicker's mix p (read from the dual prices), keeper's mix q."""
    m, n = len(A), len(A[0])
    T = [A[i][:] + [1.0 if k == i else 0.0 for k in range(m)] + [1.0] for i in range(m)]
    z = [-1.0] * n + [0.0] * (m + 1)
    basis = [n + i for i in range(m)]
    while True:
        col = next((j for j in range(n + m) if z[j] < -1e-12), None)
        if col is None:
            break
        rows = [(T[i][-1] / T[i][col], basis[i], i) for i in range(m) if T[i][col] > 1e-12]
        r = min(rows)[2]
        pv = T[r][col]
        T[r] = [v / pv for v in T[r]]
        for i in range(m):
            if i != r and T[i][col] != 0.0:
                f = T[i][col]
                T[i] = [a - f * b for a, b in zip(T[i], T[r])]
        f = z[col]
        z = [a - f * b for a, b in zip(z, T[r])]
        basis[r] = col
    V = 1.0 / z[-1]
    zq = [0.0] * n
    for i, b in enumerate(basis):
        if b < n:
            zq[b] = T[i][-1]
    return V, [z[n + i] for i in range(m)], zq, [z[n + i] * V for i in range(m)], [x * V for x in zq]

def bracket(A, p, q):
    """Certificate: the kicker's mix guarantees lo, the keeper's mix concedes at most hi."""
    lo = min(sum(p[i] * A[i][j] for i in range(len(A))) for j in range(len(A[0])))
    hi = max(sum(A[i][j] * q[j] for j in range(len(A[0]))) for i in range(len(A)))
    return lo, hi

def pure(A):
    """Plain choices only: kicker first (max-min) and keeper first (min-max)."""
    return max(min(r) for r in A), min(max(r[j] for r in A) for j in range(len(A[0])))

def pc(x):
    return f"{100 * x:.4f}%"

# ---- road 1: the 2 by 2 table, exact fractions and the closed form ----
a, b, c, d = Fr(58, 100), Fr(95, 100), Fr(93, 100), Fr(70, 100)
den = b + c - a - d
p_ex, q_ex, V_ex = (c - d) / den, (b - d) / den, (b * c - a * d) / den
print("2x2 closed form: p* =", p_ex, " q* =", q_ex, " V =", V_ex, "=", pc(float(V_ex)))
assert a * p_ex + c * (1 - p_ex) == V_ex == b * p_ex + d * (1 - p_ex)  # kicker's mix: keeper indifferent
assert a * q_ex + b * (1 - q_ex) == V_ex == c * q_ex + d * (1 - q_ex)  # keeper's mix: kicker indifferent
A, B, C, D = 58, 95, 93, 70  # the same table in whole percentage points, for the hand steps
print(f"hand: {B}*{C} = {B * C}, {A}*{D} = {A * D}, {B}+{C}-{A}-{D} = {B + C - A - D}, V = {B * C - A * D}/{B + C - A - D}")
print(f"wall: (23*{A} + 37*{C})/60 = ({23 * A} + {37 * C})/60 and (23*{B} + 37*{D})/60 = ({23 * B} + {37 * D})/60")
assert Fr(23 * A + 37 * C, 6000) == Fr(23 * B + 37 * D, 6000) == Fr(B * C - A * D, 100 * (B + C - A - D)) == V_ex
# ---- road 2: brute force over mixing rates in steps of 1/6000 ----
lo_scan = max((min(a * Fr(k, 6000) + c * (1 - Fr(k, 6000)), b * Fr(k, 6000) + d * (1 - Fr(k, 6000))), k) for k in range(6001))
hi_scan = min((max(a * Fr(k, 6000) + b * (1 - Fr(k, 6000)), c * Fr(k, 6000) + d * (1 - Fr(k, 6000))), k) for k in range(6001))
print("scan: kicker-first best", pc(float(lo_scan[0])), "at p =", f"{lo_scan[1] / 6000:.4f}",
      "| keeper-first best", pc(float(hi_scan[0])), "at q =", f"{hi_scan[1] / 6000:.4f}")
assert lo_scan[0] == V_ex == hi_scan[0]
A2 = [[0.58, 0.95], [0.93, 0.70]]
print("pure choices: kicker first", pc(pure(A2)[0]), "| keeper first", pc(pure(A2)[1]))
assert pure(A2) == (0.70, 0.93)
# ---- road 3: duality. The keeper's LP; the kicker's mix comes out as its prices ----
V2, u, zq, p2, q2 = simplex(A2)
print("keeper LP: z =", [f"{x:.6f}" for x in zq], "sum =", f"{sum(zq):.6f}", "= 1/V")
print("its prices: pi =", [f"{x:.6f}" for x in u], "sum =", f"{sum(u):.6f}", "(not a mix)")
print("rescaled by V:", f"p = {p2[0]:.4f}, q = {q2[0]:.4f}, V = {pc(V2)}")
assert abs(p2[0] - float(p_ex)) < 1e-12 and abs(q2[0] - float(q_ex)) < 1e-12
assert abs(V2 - float(V_ex)) < 1e-12
# Lagrangian dual of the kicker's problem: g(q) = max over kicker's plain choices of (A q)_i
for qL in (0.3, 25 / 60, 0.5):
    print(f"dual function at keeper Left {qL:.4f}: {pc(max(0.58 * qL + 0.95 * (1 - qL), 0.93 * qL + 0.70 * (1 - qL)))}")

# ---- the goal mouth as a line: aim u and dive v in goal widths, 0 = kicker's left post ----
def on(x):    # chance the shot is on target
    return 0.95 + 0.18 * x - 0.20 * x * x
def save(x):  # keeper's best save chance at aim x, when he dives exactly there
    return 37 / 95 + (23 / 93 - 37 / 95) * x
def score(x, y, w):  # scoring chance; the save chance falls to 0 at distance w
    return on(x) * (1.0 - save(x) * max(0.0, 1.0 - abs(x - y) / w))
def game(N, w):
    g = [k / (N - 1) for k in range(N)]
    return g, [[score(x, y, w) for y in g] for x in g]

w = 0.8
# slope bounds: |on'| <= 0.22, on <= on(0.45), save <= save(0), |save'| = 37/95 - 23/93
La = 0.22 + on(0.45) * ((37 / 95 - 23 / 93) + save(0) / w)
Ld = on(0.45) * save(0) / w
print(f"reach w = {w}; Lipschitz bounds: aim {La:.4f}, dive {Ld:.4f} per goal width")
corner = game(2, w)[1]
assert all(abs(corner[i][j] - A2[i][j]) < 1e-12 for i in range(2) for j in range(2))
print("N   V_N        bracket for the line's value   pure: kicker first  keeper first")
vals = {}
for N in (2, 3, 5, 9, 17, 33, 65, 129):
    g, A = game(N, w)
    V, _, _, p, q = simplex(A)
    lo, hi = bracket(A, p, q)
    assert abs(hi - lo) < 1e-9 and lo - 1e-9 <= V <= hi + 1e-9   # solver certified independently
    h = 1 / (N - 1)
    pmax, pmin = pure(A)
    vals[N] = (V, p, q, g)
    print(f"{N:<3} {pc(V)}  [{pc(V - Ld * h / 2)}, {pc(V + La * h / 2)}]   {pc(pmax)}  {pc(pmin)}")
    assert pmax < V - 0.05                                      # mixing closes a real gap
    assert pmin > V + 0.01
lows = [vals[N][0] - Ld / (N - 1) / 2 for N in vals]
highs = [vals[N][0] + La / (N - 1) / 2 for N in vals]
print(f"all eight brackets meet in [{pc(max(lows))}, {pc(min(highs))}]")
assert max(lows) < min(highs)   # the line's one value lies in every bracket
assert abs(vals[129][0] - vals[65][0]) < 0.0001 < abs(vals[3][0] - vals[2][0])
for N in (9, 33, 129):
    V, p, q, g = vals[N]
    A = game(N, w)[1]
    _, _, _, p2, q2 = simplex([r[::-1] for r in A])   # the same LP, keeper dives listed right to left
    q2 = q2[::-1]
    zone = lambda m, lo_, hi_: sum(m[i] for i in range(N) if lo_ <= g[i] < hi_ or (hi_ == 1 and g[i] == 1))
    kz = [zone(p, 0, 0.1), zone(p, 0.1, 0.5), zone(p, 0.5, 0.9), zone(p, 0.9, 1)]
    m1, m2 = sum(p[i] * g[i] for i in range(N)), sum(p[i] * g[i] * g[i] for i in range(N))
    print(f"N = {N}: kicker aims", " ".join(f"{x:.4f}" for x in kz), f"| posts {p[0]:.4f} {p[-1]:.4f} | mean aim {m1:.4f}, mean square {m2:.4f}")
    d1, d2, (lo2, hi2) = zone(q, 0.25, 0.5), zone(q2, 0.25, 0.5), bracket(A, p2, q2)
    print(f"  keeper dives 0.25 to 0.5: {d1:.4f} in one best mix, {d2:.4f} in another")
    assert abs(sum(kz) - 1) < 1e-9 and max(abs(a - b) for a, b in zip(p, p2)) < 1e-9  # kicker: same mix both ways
    assert abs(hi2 - lo2) < 1e-9 and abs(hi2 - V) < 1e-9 and abs(d1 - d2) > 0.04     # keeper: another best mix
for wt in (1.0, 0.5):
    print(f"try reach w = {wt}: V_2 = {pc(simplex(game(2, wt)[1])[0])}, V_3 = {pc(simplex(game(3, wt)[1])[0])}, V_65 = {pc(simplex(game(65, wt)[1])[0])}")

# ---- compactness fails: name the bigger whole number, the larger name wins 1 ----
print("bigger number: chooser of n (minimiser) from 1..N, of m (maximiser) from 1..M")
for N, M in ((10, 10), (10, 11), (100, 99), (100, 101)):
    B = [[1 if m > n else 0 for m in range(1, M + 1)] for n in range(1, N + 1)]
    up = min(max(r) for r in B)
    low = max(min(B[i][j] for i in range(N)) for j in range(M))
    print(f"  N = {N}, M = {M}: value {up}")
    assert up == low == (1 if M > N else 0)
print("ALL CHECKS PASS")
