# Differential forms and the wedge product -- the check behind the card.
# Standard library only.  A k-form is a dict {sorted index tuple: coefficient}.
# Road 1: wedge by sorting indices with a sign, evaluate by determinants of minors.
# Road 2: evaluate by the brute-force alternating sum over every ordering of the edges.
# Road 3: geometry: shoelace corners, a grid count, Lagrange's identity, a prism volume.

def perms(n):                                   # every ordering of 0..n-1, with its sign
    if n == 0:
        return [((), 1)]
    out = []
    for p, s in perms(n - 1):
        for k in range(n):                      # insert n-1 at place k: n-1-k swaps
            out.append((p[:k] + (n - 1,) + p[k:], s * (-1) ** (n - 1 - k)))
    return out

def sort_sign(idx):                             # bubble sort; each swap flips the sign
    idx, sign = list(idx), 1
    for i in range(len(idx)):
        for j in range(len(idx) - 1 - i):
            if idx[j] > idx[j + 1]:
                idx[j], idx[j + 1] = idx[j + 1], idx[j]
                sign = -sign
    return tuple(idx), sign

def wedge(a, b):                                # road 1: concatenate, sort, drop repeats
    out = {}
    for i, x in a.items():
        for j, y in b.items():
            idx, s = sort_sign(i + j)
            if len(set(idx)) == len(idx):
                out[idx] = out.get(idx, 0.0) + s * x * y
    return {k: v for k, v in out.items() if abs(v) > 1e-15}

def det(m):                                     # cofactor expansion along the top row
    if len(m) == 1:
        return m[0][0]
    return sum((-1) ** c * m[0][c] * det([r[:c] + r[c + 1:] for r in m[1:]]) for c in range(len(m)))

def ev(form, vs):                               # road 1: sum of coefficient x minor
    return sum(c * det([[v[i] for v in vs] for i in idx]) for idx, c in form.items())

def ev_brute(form, vs):                         # road 2: alternating sum over orderings
    return sum(c * s * prod_(vs[p[j]][idx[j]] for j in range(len(idx)))
               for idx, c in form.items() for p, s in perms(len(vs)))

def prod_(xs):
    r = 1.0
    for x in xs:
        r *= x
    return r

def one(cs):                                    # one-form a1 dx^1 + a2 dx^2 + ...
    return {(i,): c for i, c in enumerate(cs) if c != 0}

def f(v):
    return f"{v + 0.0:.4f}"

X, Y, Z, T = 0, 1, 2, 3
dxdy = {(X, Y): 1.0}
# ---- 1. the rain band on the weather map: edge u, swept by the wind for 3 hours ----
u, v = (120.0, 50.0), (30.0, 90.0)
A = ev(dxdy, [u, v])
corners = [(0, 0), u, (u[0] + v[0], u[1] + v[1]), v]
shoe = 0.5 * sum(corners[i][0] * corners[i - 3][1] - corners[i - 3][0] * corners[i][1] for i in range(4))
def grid(h):                                    # count cell centres inside the swept band
    n = 0
    for i in range(int(150 / h)):
        for j in range(int(140 / h)):
            px, py = (i + 0.5) * h, (j + 0.5) * h
            s = (px * v[1] - py * v[0]) / A     # solve p = s u + t v
            t = (u[0] * py - u[1] * px) / A
            n += 0 <= s < 1 and 0 <= t < 1
    return n * h * h
print("map: dx^dy(u,v) swept area km2", f(A), " dx^dy(v,u)", f(ev(dxdy, [v, u])))
print("map: u1v2 u2v1", f(u[0] * v[1]), f(u[1] * v[0]), " shoelace", f(shoe), " grid h=2", f(grid(2.0)), " grid h=1", f(grid(1.0)))
dT, dp = one([-0.04, 0.03]), one([0.01, 0.02])
TP = wedge(dT, dp)
print("map: dT(u) dT(v) dp(u) dp(v)", f(ev(dT, [u])), f(ev(dT, [v])), f(ev(dp, [u])), f(ev(dp, [v])))
print("map: dT^dp coefficient", f"{TP[(X, Y)]:.6f}", " on band", f(ev(TP, [u, v])),
      " dp^dT on band", f(ev(wedge(dp, dT), [u, v])))
assert abs(A - shoe) < 1e-9 and abs(ev(dxdy, [v, u]) + A) < 1e-9
assert abs(grid(1.0) - A) < 0.01 * A
assert abs(ev(TP, [u, v]) - (ev(dT, [u]) * ev(dp, [v]) - ev(dT, [v]) * ev(dp, [u]))) < 1e-12
# ---- 2. a hillside field in the rain: three shadows kept separately ----
U, V = (40.0, 10.0, 0.0), (-6.0, 24.0, 18.0)
sh = [ev({(Y, Z): 1.0}, [U, V]), -ev({(X, Z): 1.0}, [U, V]), ev(dxdy, [U, V])]
area = sum(s * s for s in sh) ** 0.5
lag = (sum(a * a for a in U) * sum(b * b for b in V) - sum(a * b for a, b in zip(U, V)) ** 2) ** 0.5
q = (1.5, -2.0, -6.0)                           # rain: mm/h east, north, up (falling)
rain = {(Y, Z): q[0], (X, Z): -q[1], (X, Y): q[2]}   # q2 dz^dx = -q2 dx^dz
W = ev(rain, [U, V])
prism = det([list(q), list(U), list(V)])        # water slab swept in one hour
print("hill: shadows dy^dz dz^dx dx^dy m2", f(sh[0]), f(sh[1]), f(sh[2]))
print("hill: true area", f(area), " Lagrange", f(lag), " u.v", f(sum(a * b for a, b in zip(U, V))))
print("hill: rain per shadow L/h", f(q[0] * sh[0]), f(q[1] * sh[1]), f(q[2] * sh[2]))
print("hill: rain form on field L/h", f(W), " brute", f(ev_brute(rain, [U, V])), " prism", f(prism))
print("hill: depth on slope mm/h", f(-W / area), " level gauge mm/h", f(-q[2]))
assert abs(area - lag) < 1e-9 and abs(W - prism) < 1e-9
assert abs(W - ev_brute(rain, [U, V])) < 1e-9
cross = (U[1] * V[2] - U[2] * V[1], U[2] * V[0] - U[0] * V[2], U[0] * V[1] - U[1] * V[0])   # U x V by components
assert all(abs(s - c) < 1e-9 for s, c in zip(sh, cross)) and abs(sum(a * b for a, b in zip(q, sh)) - W) < 1e-9
# ---- 3. what breaks ----
print("wrong: no sign flip, u1v2+u2v1", f(u[0] * v[1] + u[1] * v[0]))
print("wrong: dz^dx read as dx^dz", f(q[0] * sh[0] + q[1] * (-sh[1]) + q[2] * sh[2]))
print("wrong: ground shadow only", f(q[2] * sh[2]), " water all positive", f(sum(abs(a * b) for a, b in zip(q, sh))))
print("wrong: edges swapped", f(ev(rain, [V, U])))
e1, f1, f2 = (1.0, 0.0), (0.0, 1.0), (0.0, -1.0)
un = lambda a, b: abs(ev(dxdy, [a, b]))
print("fails: unsigned area of (e1,f1)+(e1,f2)", f(un(e1, f1) + un(e1, f2)), " of (e1,f1+f2)", f(un(e1, (f1[0] + f2[0], f1[1] + f2[1]))))
# ---- 4. the sign rule ----
al, be = one([1.0, 2.0, 0.0]), one([0.0, 3.0, -1.0])
ab, ba = wedge(al, be), wedge(be, al)
print("rule: a^b", [f(ab[k]) for k in sorted(ab)], " b^a", [f(ba[k]) for k in sorted(ba)])
print("rule: a^a terms", len(wedge(al, al)), " dz^rain", f(wedge(one([0, 0, 1.0]), rain)[(X, Y, Z)]),
      " rain^dz", f(wedge(rain, one([0, 0, 1.0]))[(X, Y, Z)]))
P = [(3.0, -1.0, 2.0), (0.5, 4.0, 1.0)]
assert all(abs(ab[k] + ba[k]) < 1e-12 for k in ab) and wedge(al, al) == {}
assert abs(ev(ab, P) - (ev(al, [P[0]]) * ev(be, [P[1]]) - ev(al, [P[1]]) * ev(be, [P[0]]))) < 1e-12
# ---- 5. four dimensions: x, y, z, t ----
sig = wedge(one([1.0, 2.0, 0.0, 0.0]), one([0.0, 0.0, 3.0, -1.0]))
tau = {(X, Y): 1.0, (Z, T): 1.0}
cnt = [len(wedge(one([1.0] * n), one([(i + 1.0) ** 2 for i in range(n)]))) for n in (2, 3, 4, 5)]
print("4D: components of a two-form, n = 2 3 4 5:", cnt)
assert cnt == [n * (n - 1) // 2 for n in (2, 3, 4, 5)]
print("4D: sig^sig", len(wedge(sig, sig)), "terms;  tau^tau", f(wedge(tau, tau)[(X, Y, Z, T)]))
Q4 = [(1.0, 0.0, 0.0, 0.0), (0.0, 1.0, 0.0, 0.0), (0.0, 0.0, 1.0, 0.0), (0.0, 0.0, 0.0, 1.0)]
print("4D: tau^tau on the unit box, brute", f(ev_brute(wedge(tau, tau), Q4)))
assert wedge(sig, sig) == {} and abs(ev_brute(wedge(tau, tau), Q4) - 2.0) < 1e-12
# ---- 6. try changing ----
print("try: wind along the edge", f(ev(dxdy, [u, (60.0, 25.0)])),
      " parallel isotherms", f(ev(wedge(one([-0.02, -0.04]), dp), [u, v])))
print("try: crosswind north -4", f(ev({(Y, Z): 1.5, (X, Z): 4.0, (X, Y): -6.0}, [U, V])))
print("ALL CHECKS PASS")
