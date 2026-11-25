# Kahler differentials on the cusp y^2 = x^3 and on the smooth cubic y^2 = x^3 - x.
# Standard library only. A polynomial is a dict {(i, j): c} for c x^i y^j, c a Fraction: exact.
# A 1-form P dx + Q dy is the pair (P, Q); the one relation of a plane curve f = 0 is df.
# Road 1: the presentation: fibre dimension at a point = 2 - rank of (f_x, f_y) there.
# Road 2: dual numbers a + b e with e^2 = 0, no derivatives: solutions v of f(P + e v) = 0.
# Road 3: weights x:2, y:3 on the cusp, against the pullback to the line t -> (t^2, t^3).
# Road 4: exact certificates for the smooth cubic, substituted back and reduced mod f.
from fractions import Fraction as Fr

def cl(h): return {m: c for m, c in h.items() if c}
def add(*fs):
    h = {}
    for f in fs:
        for m, c in f.items(): h[m] = h.get(m, 0) + c
    return cl(h)
def mul(f, g):
    h = {}
    for (a, b), c in f.items():
        for (e, k), u in g.items(): h[(a + e, b + k)] = h.get((a + e, b + k), 0) + c * u
    return cl(h)
def sc(c, f): return cl({m: c * u for m, u in f.items()})
def nf(p, g):  # remainder modulo y^2 - g(x): swap each y^2 for g
    while any(j > 1 for (i, j) in p):
        m = max(m for m in p if m[1] > 1); c = p.pop(m)
        p = add(p, sc(c, mul({(m[0], m[1] - 2): 1}, g)))
    return p
def d(f, k): return cl({((i - 1, j) if k == 0 else (i, j - 1)): c * (i, j)[k] for (i, j), c in f.items() if (i, j)[k]})
def ev(f, P, q=0):
    s = sum(c * P[0] ** i * P[1] ** j for (i, j), c in f.items())
    return int(s) % q if q else s
def dual(f, P, v, q=0):  # f(P + e v) with e^2 = 0, by dual-number arithmetic only
    A = B = 0
    for (i, j), c in f.items():
        a, b = int(c), 0
        for p0, v0, n in ((P[0], v[0], i), (P[1], v[1], j)):
            for _ in range(n): a, b = a * p0, a * v0 + b * p0
        A, B = A + a, B + b
    return (A % q, B % q) if q else (A, B)
def show(f):
    out = ""
    for (i, j) in sorted(f, reverse=True):
        c = f[(i, j)]; a = abs(c)
        mono = ("x" + (f"^{i}" if i > 1 else "") if i else "") + ("y" + (f"^{j}" if j > 1 else "") if j else "")
        cs = "" if a == 1 and mono else (str(a) if a.denominator == 1 or not mono else f"({a})")
        out += (("-" if c < 0 else "") if not out else (" - " if c < 0 else " + ")) + cs + mono
    return out or "0"
def fib(f, P, q=0):  # road 1: the relation df at P, and 2 - its rank
    r = (ev(d(f, 0), P, q), ev(d(f, 1), P, q)); return r, 2 - (r != (0, 0))
def nsol(f, P, q):  # road 2: count v in F_q^2 with f(P + e v) = 0
    return sum(dual(f, P, (a, b), q) == (0, 0) for a in range(q) for b in range(q))

cusp = {(0, 2): Fr(1), (3, 0): Fr(-1)}; g0 = {(3, 0): Fr(1)}
cub = {(0, 2): Fr(1), (3, 0): Fr(-1), (1, 0): Fr(1)}; g1 = {(3, 0): Fr(1), (1, 0): Fr(-1)}
print("field: the rationals Q, exact; F_p only where named")
for name, f in (("cusp", cusp), ("smooth cubic", cub)):
    print(f"{name} f = {show(f)}: Omega = (A dx + A dy) / (df), df = ({show(d(f, 0))}) dx + ({show(d(f, 1))}) dy")
for name, f, P in (("cusp", cusp, (0, 0)), ("cusp", cusp, (1, 1)), ("cubic", cub, (-1, 0)), ("cubic", cub, (0, 0)), ("cubic", cub, (1, 0))):
    r, k = fib(f, P); lin = (dual(f, P, (1, 0))[1], dual(f, P, (0, 1))[1])
    print(f"{name} at {P}: f = {ev(f, P)}; df there = {r[0]} dx + {r[1]} dy; dual numbers give {lin[0]}a + {lin[1]}b; fibre dimension {k}")
    assert ev(f, P) == 0 and lin == r
r, _ = fib(cusp, (1, 1)); slope = Fr(-r[0], r[1])
print(f"cusp at (1, 1): dy = {slope} dx; velocity of (t^2, t^3) at t = 1 is (2, 3), slope {Fr(3 * 1 ** 2, 2 * 1)}")
assert slope == Fr(3 * 1 ** 2, 2 * 1) and fib(cusp, (0, 0))[1] == 2
roots = [a for a in range(-3, 4) if a ** 3 - a == 0]
print(f"cubic: 2y = 0 forces y = 0, so x^3 - x = 0: x = {roots}; 3x^2 - 1 there: {[3 * a * a - 1 for a in roots]}; no singular point")
assert all(3 * a * a - 1 != 0 for a in roots) and len(roots) == 3
u, v = {(2, 0): Fr(3, 2), (0, 0): Fr(-1)}, {(1, 1): Fr(-9, 4)}
a3, b2 = sc(-1, d(cub, 0)), d(cub, 1)  # 3x^2 - 1 and 2y: the relation reads 2y dy = (3x^2 - 1) dx
one = nf(add(mul(u, a3), mul(v, b2)), g1)
print(f"certificate: ({show(u)})(3x^2 - 1) + ({show(v)})(2y) = {show(one)} mod f")
X, c1 = {(1, 0): Fr(1)}, {(0, 0): Fr(1)}
s1 = add(mul(sc(Fr(1, 3), X), a3), sc(Fr(-2, 3), X), sc(-1, g1))  # x^3 - x = (x/3)(3x^2 - 1) - (2/3)x
s2 = add(mul(sc(Fr(-9, 2), X), sc(Fr(-2, 3), X)), sc(-1, c1), sc(-1, a3))  # 3x^2 - 1 = (-(9/2)x)(-(2/3)x) - 1
s3 = add(mul(u, a3), mul(sc(Fr(-9, 2), X), g1))  # 1 = u (3x^2 - 1) - (9/2) x (x^3 - x)
print(f"division steps: x^3 - x = (x/3)(3x^2 - 1) - (2/3)x; 3x^2 - 1 = (-(9/2)x)(-(2/3)x) - 1; back-substituted: {show(s3)}")
assert one == c1 and s1 == {} and s2 == {} and s3 == c1
rel = (d(cub, 0), d(cub, 1)); w = (v, u)  # w = u dy + v dx
e1 = [nf(add(t, sc(-1, s)), g1) for t, s in zip(({(0, 0): Fr(1)}, {}), ((mul(b2, w[0])), mul(b2, w[1])))]
e2 = [nf(add(t, sc(-1, s)), g1) for t, s in zip(({}, {(0, 0): Fr(1)}), ((mul(a3, w[0])), mul(a3, w[1])))]
ok1 = all(nf(add(e, mul(u, m)), g1) == {} for e, m in zip(e1, rel))
ok2 = all(nf(add(e, sc(-1, mul(v, m))), g1) == {} for e, m in zip(e2, rel))
print(f"w = ({show(u)}) dy + ({show(v)}) dx: dx - 2y w = -u df: {ok1}; dy - (3x^2 - 1) w = v df: {ok2}")
D = nf(add(mul(b2, rel[0]), mul(a3, rel[1])), g1)
print(f"derivation D = 2y d/dx + (3x^2 - 1) d/dy: D(f) = {show(D)}; phi(dx) = 2y, phi(dy) = 3x^2 - 1, phi(w) = {show(one)}")
assert ok1 and ok2 and D == {}
for q in (7, 13):
    for name, f in (("cusp", cusp), ("cubic", cub)):
        pts = [(a, b) for a in range(q) for b in range(q) if ev(f, (a, b), q) == 0]
        k1 = [fib(f, P, q)[1] for P in pts]; k2 = [nsol(f, P, q) for P in pts]
        sing = [P for P, k in zip(pts, k1) if k == 2]
        print(f"over F_{q}: {name} {len(pts)} points; fibre 2 at {sing}, 1 at {k1.count(1)}; dual-number counts {sorted(set(k2))}")
        gx = sc(-1, add(f, {(0, 2): Fr(-1)}))  # f = y^2 - g(x); count by Euler's criterion
        chi = lambda n: 0 if n == 0 else (1 if pow(n, (q - 1) // 2, q) == 1 else -1)
        euler = sum(1 + chi(ev(gx, (a, 0), q)) for a in range(q))
        assert all(n == q ** k for n, k in zip(k2, k1)) and len(pts) == euler and sing == ([(0, 0)] if f is cusp else [])
wt = lambda m: 2 * m[0] + 3 * m[1]
A = lambda n: sum(1 for i in range(n // 2 + 1) for j in (0, 1) if 2 * i + 3 * j == n)  # basis x^i y^j, j < 2
om = [A(n - 2) + A(n - 3) - A(n - 6) for n in range(13)]
img = [1 if A(n - 2) + A(n - 3) else 0 for n in range(13)]  # x^i y^j dx -> 2t^(2i+3j+1) dt, dy -> 3t^(..+2) dt
tor = [p - q for p, q in zip(om, img)]
print(f"cusp by weight 0..12: dim Omega_n {om}; image in k[t] dt {img}; torsion {tor}")
assert sum(tor) == 2 and [n for n in range(13) if tor[n]] == [5, 7]
sub = lambda p: cl({(2 * i + 3 * j, 0): c for (i, j), c in p.items()})
tw = ({(0, 1): Fr(-3)}, {(1, 0): Fr(2)})  # w0 = 2x dy - 3y dx
pb = add(mul(sub(tw[0]), {(1, 0): Fr(2)}), mul(sub(tw[1]), {(2, 0): Fr(3)}))
cr = (d(cusp, 0), d(cusp, 1))
ky = all(nf(add(mul({(0, 1): 1}, a), sc(-1, mul({(1, 0): 1}, b))), g0) == {} for a, b in zip(tw, cr))
kx = all(nf(add(mul({(2, 0): 1}, a), sc(-1, mul({(0, 1): 1}, b))), g0) == {} for a, b in zip(tw, cr))
print(f"weights x {wt((1, 0))}, y {wt((0, 1))}, df {wt((0, 2))}; w0 = 2x dy - 3y dx, weight {wt((1, 0)) + wt((0, 1))}: pullback {show(pb)}; y w0 = x df: {ky}; x^2 w0 = y df: {kx}")
assert pb == {} and ky and kx
sq = mul(cub, cub)
p7 = [(a, b) for a in range(7) for b in range(7) if ev(cub, (a, b), 7) == 0]
m1 = [sum(fib(g, P, 7)[1] == 2 for P in p7) for g in (sq, cub)]
print(f"mistake 1, f^2 over F_7: fibre 2 at {m1[0]} of {len(p7)} points; with f: {m1[1]}")
p2 = [(a, b) for a in range(2) for b in range(2) if ev(cub, (a, b), 2) == 0]
print(f"mistake 2, cubic over F_2: points {p2}; fibres {[fib(cub, P, 2)[1] for P in p2]}; dual-number counts {[nsol(cub, P, 2) for P in p2]}")
assert [fib(cub, P, 2)[1] for P in p2] == [1, 2] and [nsol(cub, P, 2) for P in p2] == [2, 4] and m1 == [len(p7), 0]
unev, ev0 = 2 - (cr != ({}, {})), fib(cusp, (0, 0))[1]
print(f"mistake 3, df of the cusp left unevaluated: not zero, so 'fibre' {unev}; evaluated at (0, 0): {ev0}")
assert (unev, ev0) == (1, 2)
print(f"mistake 4, pull back to the line: w0 becomes {show(pb)}, torsion invisible; true torsion dimension {sum(tor)}")
print(f"house: plane curve of degree d = 3: genus (d - 1)(d - 2)/2 = {(3 - 1) * (3 - 2) // 2}; Omega = O(d - 3) = O({3 - 3})")
vert = [f"({a},0)" for a in roots if fib(cub, (a, 0))[0][1] == 0 and fib(cub, (a, 0))[1] == 1]  # f_y = 0, f_x != 0
print(f"figure, cusp: (0,0) singular, (1,1) slope {slope}; cubic: {' '.join(vert)} vertical; cusp x -1..2.2, cubic x -1.5..2.2, y -3.2..3.2")
print("ALL CHECKS PASS")
