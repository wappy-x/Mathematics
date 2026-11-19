# Fundamental theorem of curves -- the check behind the card.  Standard library
# only.  A ski run is known only by its bend kappa and twist tau (1/m) along the
# distance s skied (m).  The frame equations T' = kN, N' = -kT + tB, B' = -tN,
# r' = T are stepped by RK4 to rebuild it.  Roads: the helix formula, bend and
# twist measured back off the rebuilt points, and a second start.
import math

K0, TW = 0.012, 0.0024                       # the survey: bend and twist, 1/m
W2 = K0 * K0 + TW * TW
A, C, RAD = K0 / W2, TW / W2, 1 / math.sqrt(W2)   # radius, drop per radian, m per radian
L = 2 * math.pi * RAD                         # one full turn of the run, m

def add(u, v, k=1.0): return [u[0] + k * v[0], u[1] + k * v[1], u[2] + k * v[2]]
def dot(u, v): return u[0] * v[0] + u[1] * v[1] + u[2] * v[2]
def cross(u, v): return [u[1]*v[2] - u[2]*v[1], u[2]*v[0] - u[0]*v[2], u[0]*v[1] - u[1]*v[0]]
def dist(u, v): return math.sqrt(dot(add(u, v, -1.0), add(u, v, -1.0)))
def f(x, d): return f"{0.0 if abs(x) < 0.5 * 10.0 ** -d else x:.{d}f}"
def pt(p): return "(" + ", ".join(f(x, 2) for x in p) + ")"

def rates(st, k, t):                         # the Frenet-Serret equations
    r, T, N, Bv = st
    return [T, [k * x for x in N], add([-k * x for x in T], Bv, t), [-t * x for x in N]]

def step(st, kap, tau, s, h, euler):
    k1 = rates(st, kap(s), tau(s))
    if euler:
        return [add(st[j], k1[j], h) for j in range(4)]
    k2 = rates([add(st[j], k1[j], h / 2) for j in range(4)], kap(s + h / 2), tau(s + h / 2))
    k3 = rates([add(st[j], k2[j], h / 2) for j in range(4)], kap(s + h / 2), tau(s + h / 2))
    k4 = rates([add(st[j], k3[j], h) for j in range(4)], kap(s + h), tau(s + h))
    return [[st[j][i] + h / 6 * (k1[j][i] + 2 * k2[j][i] + 2 * k3[j][i] + k4[j][i])
             for i in range(3)] for j in range(4)]

def rebuild(st, kap, tau, length, n, euler=False):   # n equal steps; every position kept
    h, pts = length / n, [st[0]]
    for i in range(n):
        st = step(st, kap, tau, i * h, h, euler)
        pts.append(st[0])
    return st, pts

def start(r0, T0, N0): return [r0, T0, N0, cross(T0, N0)]
def helix(s): return [A * math.sin(s / RAD), -A * (1 - math.cos(s / RAD)), -C * s / RAD]
def chord(dt): return math.sqrt(2 * A * A * (1 - math.cos(dt)) + C * C * dt * dt)
def vol(p): return dot(cross(add(p[1], p[0], -1.0), add(p[2], p[0], -1.0)), add(p[3], p[0], -1.0))
kc, tc = (lambda s: K0), (lambda s: TW)
S0 = start([0.0, 0.0, 0.0], [A / RAD, 0.0, -C / RAD], [0.0, -1.0, 0.0])

print(f"survey: bend {f(K0, 4)} 1/m, twist {f(TW, 4)} 1/m, turn radius 1/bend {f(1 / K0, 2)} m")
print(f"helix: radius {f(A, 3)} m, drop per radian {f(C, 3)} m, grade twist/bend {f(TW / K0, 3)}"
      f" = {f(math.degrees(math.atan(TW / K0)), 2)} deg")
print(f"bend^2 + twist^2 = {f(W2, 8)} 1/m^2; {f(RAD, 3)} m per radian; one turn: length {f(L, 2)} m, drop {f(2 * math.pi * C, 2)} m")
print(f"start frame: T {pt(S0[1])}, N {pt(S0[2])}, B {pt(S0[3])}")
T1, N1, B1 = add(S0[1], S0[2], 10 * K0), add(S0[2], add([-K0 * x for x in S0[1]], S0[3], TW), 10.0), add(S0[3], S0[2], -10 * TW)
r1 = add([10 * x for x in S0[1]], S0[2], 50 * K0)          # one 10 m step by hand; r'' = T' = kN gives the 50 k N
print(f"one 10 m step by hand: T {pt(T1)}, N {pt(N1)}, B {pt(B1)}; r = 10 T + 50 k N = {pt(r1)}, helix {pt(helix(10.0))}, {f(dist(r1, helix(10.0)), 3)} m apart")
for n in (52, 512):
    end, pts = rebuild(S0, kc, tc, L, n)
    err = max(dist(pts[i], helix(i * L / n)) for i in range(0, n + 1, n // 4))
    print(f"RK4, step {f(L / n, 3)} m: finish {pt(end[0])}, worst miss at quarter points {f(1000 * err, 4)} mm")
fine = pts
for q in range(5):
    print(f"s = {f(q * L / 4, 2)} m: rebuilt {pt(fine[q * 128])}, helix formula {pt(helix(q * L / 4))}")
print(f"frame still orthonormal at finish: |T| = {f(math.sqrt(dot(end[1], end[1])), 9)}, T.N = {f(dot(end[1], end[2]), 9)}")
S2 = start([350.0, 120.0, -40.0], [0.0, A / RAD, -C / RAD], [1.0, 0.0, 0.0])   # another place, heading north
end2, pts2 = rebuild(S2, kc, tc, L, 512)
print(f"second start (350, 120, -40) heading north: finish {pt(end2[0])}")
for (i, j) in ((0, 128), (0, 256), (128, 384), (0, 512)):
    c1, c2, c3 = dist(fine[i], fine[j]), dist(pts2[i], pts2[j]), chord(math.pi * (j - i) / 256)
    print(f"chord quarter {i // 128} to {j // 128}: run 1 {f(c1, 3)} m, run 2 {f(c2, 3)} m, formula {f(c3, 3)} m")
    assert abs(c1 - c3) < 1e-6 and abs(c2 - c3) < 1e-6           # rigid copies, one shape
kt = lambda s: 0.006 + 0.00002 * s                               # a run whose bend tightens
e10, _ = rebuild(S0, kt, tc, 500.0, 50)
e1, p1 = rebuild(S0, kt, tc, 500.0, 500)
print(f"tightening run, 500 m: finish at step 10 m {pt(e10[0])}, at 1 m {pt(e1[0])}, gap {f(1000 * dist(e10[0], e1[0]), 3)} mm")
for s in (100, 250, 400):                   # measure back: any-speed formulas, 1 m differences
    m2, m1, z, q1, q2 = p1[s - 2], p1[s - 1], p1[s], p1[s + 1], p1[s + 2]
    d1 = [(q1[i] - m1[i]) / 2 for i in range(3)]
    d2 = [q1[i] - 2 * z[i] + m1[i] for i in range(3)]
    d3 = [(q2[i] - 2 * q1[i] + 2 * m1[i] - m2[i]) / 2 for i in range(3)]
    x = cross(d1, d2)
    km, tm = math.sqrt(dot(x, x)) / dot(d1, d1) ** 1.5, dot(x, d3) / dot(x, x)
    print(f"measured back at s = {s} m: bend {f(km, 6)} (asked {f(kt(s), 6)}), twist {f(tm, 7)} (asked {f(TW, 7)})")
    assert abs(km - kt(s)) < 1e-6 and abs(tm - TW) < 1e-7        # the rebuilt run has the asked bend and twist
mir, pm = rebuild(S0, kc, lambda s: -TW, L, 512)
flat, _ = rebuild(S0, kc, lambda s: 0.0, L, 512)
eul, _ = rebuild(S0, kc, tc, L, 512, euler=True)
fin = helix(L)
v1, v2 = vol([fine[0], fine[128], fine[256], fine[384]]), vol([pm[0], pm[128], pm[256], pm[384]])
print(f"handedness, signed volume of quarter-point chords: run {f(v1, 0)} m^3, twist flipped {f(v2, 0)} m^3")
print(f"mistake 1, twist dropped: finish {pt(flat[0])}, {f(dist(flat[0], fin), 2)} m from the bottom station")
print(f"mistake 2, twist sign flipped: finish {pt(mir[0])}, {f(dist(mir[0], fin), 2)} m from the bottom station")
print(f"mistake 3, Euler steps of {f(L / 512, 3)} m: finish {pt(eul[0])}, {f(dist(eul[0], fin), 2)} m off, |T| = {f(math.sqrt(dot(eul[1], eul[1])), 4)}")
q = 128                                     # mistake 4: a straight 60 m schuss, where bend = 0
for spin in (0, 90):
    st, _ = rebuild(S0, kc, tc, L / 4, q)
    st[0] = add(st[0], st[1], 60.0)
    if spin:                                # bend 0: N and B are free to turn about T
        st[2], st[3] = st[3], [-x for x in st[2]]
    st, _ = rebuild(st, kc, tc, L / 4, q)
    print(f"mistake 4, turn, 60 m straight, turn, frame spun {spin} deg on the straight: finish {pt(st[0])}, {f(dist(st[0], [0.0, 0.0, 0.0]), 2)} m from the top")
print(f"figure, plan centre (0.00, {f(-A, 2)}), radius {f(A, 2)}; side: x = {f(A, 2)} sin(s/{f(RAD, 3)}), z = -{f(C, 3)} s/{f(RAD, 3)}")
assert dist(fine[512], fin) < 1e-5 and dist(fine[256], helix(L / 2)) < 1e-5   # RK4 against the formula
assert v1 > 1000 and abs(v1 + v2) < 1e-3 * abs(v1)                          # a mirror flips handedness
assert dist(mir[0], fin) > 1 and dist(flat[0], fin) > 1                     # the twist matters
print("ALL CHECKS PASS")
