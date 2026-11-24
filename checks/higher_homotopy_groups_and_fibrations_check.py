# Higher homotopy groups and the Hopf fibration -- the check behind the card.  Standard library only.
# A point of S^3 is a pair of complex numbers (z, w) with |z|^2 + |w|^2 = 1.  The Hopf map h sends
# it to the ratio z/w on the Riemann sphere, drawn as the point (2 z conj(w), |z|^2 - |w|^2) of S^2.
from math import sqrt, pi, cos, sin, atan2
from itertools import product

def f6(x):                                  # six decimals, with no "-0.000000"
    return f"{0.0 if abs(x) < 5e-7 else x:.6f}"

def cf(c):                                  # a complex number as "a + bi"
    return f"{f6(c.real)} {'-' if c.imag < -5e-7 else '+'} {f6(abs(c.imag))}i"

def yes(ok): return "yes" if ok else "no"

def bloch(z, w):                            # road one to h: the point of S^2
    q = 2 * z * w.conjugate()
    return (q.real, q.imag, abs(z) ** 2 - abs(w) ** 2)

def stereo(p):                              # S^2 minus its top pole -> the plane, as a complex number
    return complex(p[0], p[1]) / (1 - p[2])

def phase(t):
    return complex(cos(t), sin(t))

def winding(seq):                           # turns of a closed walk round 0, adding short angle steps
    return sum(atan2((b1 / b0).imag, (b1 / b0).real) for b0, b1 in zip(seq, seq[1:])) / (2 * pi)

M = 0xFFFFFFFFFFFFFFFF
def splitmix(s):                            # SplitMix64, seed 2026: the same points in Python and Rust
    while True:
        s = (s + 0x9E3779B97F4A7C15) & M
        x = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M
        x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & M
        yield ((x ^ (x >> 31)) >> 11) / 2.0 ** 53 * 2 - 1

def random_s3(g):
    v = [next(g) for _ in range(4)]
    r = sqrt(sum(c * c for c in v))
    return complex(v[0], v[1]) / r, complex(v[2], v[3]) / r

r2 = 1 / sqrt(2)
z, w = complex(r2, 0), complex(r2, 0)       # the example qubit
b = bloch(z, w)
print(f"example (z, w) = ({f6(r2)}, {f6(r2)}): |z|^2 + |w|^2 = {f6(abs(z)**2 + abs(w)**2)}, chance of 0 = {f6(abs(z)**2)}")
print(f"  ratio z/w = {cf(z / w)}; point of S^2 = ({f6(b[0])}, {f6(b[1])}, {f6(b[2])})")
fib = [(phase(2 * pi * k / 12) * z, phase(2 * pi * k / 12) * w) for k in range(12)]
dev = max(abs(a / c - 1) for a, c in fib)
print(f"  12 points (e^(it) z, e^(it) w), t = 0, 30, ..., 330 deg: every ratio within 1e-12 of 1: {yes(dev < 1e-12)}")
print(f"  t = 90 deg: ({cf(fib[3][0])}, {cf(fib[3][1])})")
z2, w2 = complex(0.6, 0), complex(0, 0.8)
b2, q2 = bloch(z2, w2), z2 / w2
print(f"second qubit (3/5, 4i/5): ratio = {cf(q2)}; point = ({f6(b2[0])}, {f6(b2[1])}, {f6(b2[2])});"
      f" stereographic = {cf(stereo(b2))}")
g = splitmix(2026)
pts = [random_s3(g) for _ in range(1000)]
e1 = max(abs(stereo(bloch(a, c)) - a / c) for a, c in pts)
e2 = max(max(abs(x - y) for x, y in zip(bloch(a, c), bloch(phase(t) * a, phase(t) * c))) for a, c in pts for t in (1, 2, 3))
print(f"1000 random points: two roads to h agree within 1e-9: {yes(e1 < 1e-9)}; a phase moves h under 1e-12: {yes(e2 < 1e-12)}")

def s3_to_r3(a, c):                         # stereographic projection of S^3 from the point (0, i) into space
    return (a.real / (1 - c.imag), a.imag / (1 - c.imag), c.real / (1 - c.imag))

def gauss_link(p, q, n=200):                # road one to linking: Gauss's double sum over two polygons
    P = [s3_to_r3(phase(2 * pi * k / n) * p[0], phase(2 * pi * k / n) * p[1]) for k in range(n)]
    Q = [s3_to_r3(phase(2 * pi * k / n) * q[0], phase(2 * pi * k / n) * q[1]) for k in range(n)]
    tot = 0.0
    for i in range(n):
        a0, a1 = P[i], P[(i + 1) % n]
        for j in range(n):
            c0, c1 = Q[j], Q[(j + 1) % n]
            r = [(a0[k] + a1[k] - c0[k] - c1[k]) / 2 for k in range(3)]
            u = [a1[k] - a0[k] for k in range(3)]
            v = [c1[k] - c0[k] for k in range(3)]
            cr = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
            tot += sum(r[k] * cr[k] for k in range(3)) / sqrt(sum(x * x for x in r)) ** 3
    return tot / (4 * pi)

def disc_crossings(p, q, n=360):            # road two: fibre q crossing the disc {x : p0 x1 - p1 x0 real, >= 0}
    d = p[0] * q[1] - p[1] * q[0]           # that fibre p bounds, counted with sign
    vals = [phase(2 * pi * k / n) * d for k in range(n + 1)]
    return sum((v1.imag > 0) - (v0.imag > 0) for v0, v1 in zip(vals, vals[1:]) if v0.real > 0 and v1.real > 0)

others = {"-1": (complex(r2), complex(-r2)), "infinity": (complex(1), complex(0)), "i": (complex(r2), complex(0, -r2))}
links = {k: gauss_link((z, w), v) for k, v in others.items()}
for k, v in others.items():
    print(f"fibre over 1 and fibre over {k}: Gauss sum {links[k]:.3f}, disc crossings {disc_crossings((z, w), v)}")
cross = [disc_crossings(pts[2 * i], pts[2 * i + 1]) for i in range(500)]
print(f"500 random pairs of fibres: disc crossings {sorted(set(cross))}")

def tri_angle(a, b, c):                     # signed solid angle of a small spherical triangle
    det = a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0]) + a[2] * (b[0] * c[1] - b[1] * c[0])
    return 2 * atan2(det, 1 + sum(a[k] * b[k] + b[k] * c[k] + c[k] * a[k] for k in range(3)))

print("boundary map: the map (theta, phi) -> (theta, d phi) of S^2, lifted to S^3")
bmap, T, F = {}, 24, 48
for d in range(-2, 3):
    pt = lambda i, j: (sin(pi * i / T) * cos(d * 2 * pi * j / F), sin(pi * i / T) * sin(d * 2 * pi * j / F), cos(pi * i / T))
    deg = sum(tri_angle(pt(i, j), pt(i + 1, j), pt(i + 1, j + 1)) + tri_angle(pt(i, j), pt(i + 1, j + 1), pt(i, j + 1))
              for i in range(T) for j in range(F)) / (4 * pi)
    lift = lambda i, j: (complex(cos(pi * i / T / 2), 0), sin(pi * i / T / 2) * phase(-d * 2 * pi * j / F))
    err = max(abs(x - y) for i in range(T + 1) for j in range(F) for x, y in zip(bloch(*lift(i, j)), pt(i, j)))
    wind = winding([lift(T, j)[1] for j in range(F + 1)])
    bmap[d] = (deg, wind, err)
    print(f"  d = {d:2d}: degree by area {f6(deg)}; lift within 1e-12: {yes(err < 1e-12)}; rim in the fibre winds {f6(wind)}")

E = range(3)                                # Eckmann-Hilton: every operation on {0, 1, 2} with unit 0
ops = []
for v in product(E, repeat=4):
    t = {(0, a): a for a in E} | {(a, 0): a for a in E}
    t[1, 1], t[1, 2], t[2, 1], t[2, 2] = v
    ops.append(t)
quads = list(product(E, repeat=4))
inter = [(o, s) for o in ops for s in ops if all(s[o[a, b], o[c, d]] == o[s[a, c], s[b, d]] for a, b, c, d in quads)]
same = sum(1 for o, s in inter if o == s and all(o[a, c] == o[c, a] for a in E for c in E))
mon = [o for o in ops if all(o[o[a, c], e] == o[a, o[c, e]] for a in E for c in E for e in E)]
comm = [o for o in mon if all(o[a, c] == o[c, a] for a in E for c in E)]
print(f"Eckmann-Hilton on 3 elements: {len(ops)} operations, {len(ops) ** 2} pairs; {len(inter)} pairs obey the"
      f" interchange law, {same} of them equal and commutative")
print(f"  monoids with unit 0: {len(mon)}; commutative {len(comm)}; not commutative {len(mon) - len(comm)}")
pi_s1 = lambda k: "Z" if k == 1 else "0"                              # from the cover R -> S^1
pi_s3 = lambda k: {3: "Z", 4: "Z2", 5: "Z2", 6: "Z12"}.get(k, "0")    # stated: Hatcher's table
pi_s2 = lambda k: pi_s1(k - 1) if k <= 2 else pi_s3(k)                # exactness, neighbours 0
for k in (1, 2, 3):
    print(f"Hopf sequence, k = {k}: pi_{k}(S^3) = {pi_s3(k)}, pi_{k - 1}(S^1) = {pi_s1(k - 1) if k > 1 else 'point'}"
          f" -> pi_{k}(S^2) = {pi_s2(k)}")
rows = {1: [pi_s1(k) for k in range(1, 7)], 2: [pi_s2(k) for k in range(1, 7)], 3: [pi_s3(k) for k in range(1, 7)],
        4: ["0", "0", "0", "Z", "Z2", "Z2"]}                           # S^4: stated, Hatcher's table
for n, r in rows.items():
    print(f"pi_1..pi_6 of S^{n}: {' '.join(f'{x:>3}' for x in r)}")
loop1 = winding([phase(2 * pi * k / 360) for k in range(361)])
print(f"mistake, [0, 1) -> S^1 as a fibration: fibres are points, so exactness says pi_1(S^1) = 0;"
      f" the loop e^(2 pi i t) winds {f6(loop1)}")
print(f"mistake, judge h by homology: H_3(S^2) = 0, so h gives 0 there; fibres still link {round(links['-1'])}")
assert abs(b[0] - 1) < 1e-12 and dev < 1e-12 and e1 < 1e-9 and e2 < 1e-12  # two roads to h; phases invisible
assert all(abs(x - 1) < 0.01 for x in links.values())                # Gauss sum near 1 ...
assert set(cross) == {1} and all(disc_crossings((z, w), v) == 1 for v in others.values())  # ... crossings 1
assert all(abs(dg - d) < 1e-9 and abs(wd + d) < 1e-9 and er < 1e-12 for d, (dg, wd, er) in bmap.items())
assert len(inter) == same == len(comm) == 9 and len(mon) - len(comm) == 2  # Eckmann-Hilton, exhaustively
assert abs(q2 - stereo(b2)) < 1e-12 and abs(q2 + 0.75j) < 1e-12 and abs(loop1 - 1) < 1e-9
print("ALL CHECKS PASS")
