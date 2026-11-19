# Hairy ball theorem: a field on a sphere must stand still somewhere -- the check behind the card.
# Standard library only.  The Earth is a sphere of radius 6371 km.  A model pressure map
# p = 1013 + 20 s hPa, with s = 3 sqrt(3) x y z, has 4 highs, 4 lows and 6 cols (saddles).
# The surface wind is W = -grad p.  Roads to the total index 2 = chi(sphere):
# 1 walk a small loop round each calm spot and count the wind's turns;
# 2 the sign of the determinant of the wind's linear part at each calm spot;
# 3 sweep the whole globe in 486 cells, never told where the calm spots are;
# 4 V - E + F of that same grid.  Then a doughnut world, where the total is 0.
import math
TAU, RKM, DEG = 2 * math.pi, 6371.0, 180 / math.pi
A = 20 * 3 * math.sqrt(3)

def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
def unit(a): n = math.sqrt(dot(a, a)); return tuple(x / n for x in a)
def pressure(r): return 1013 + A * r[0] * r[1] * r[2]
def wind(r):                                   # -grad p, tangent to the globe, hPa per Earth radius
    g = (A * r[1] * r[2], A * r[0] * r[2], A * r[0] * r[1])
    k = dot(g, r)
    return tuple(-(gi - k * ri) for gi, ri in zip(g, r))
def turned(r): return cross(r, wind(r))        # every arrow given a quarter turn: wind along isobars
def east(r): return (-10 * r[1], 10 * r[0], 0.0)   # steady east wind, 10 m/s at the equator
def frame(p):                                  # e1, e2 tangent at p, with e1 x e2 = p (outward)
    e1 = unit(cross((0.0, 0.0, 1.0) if abs(p[2]) < 0.9 else (1.0, 0.0, 0.0), p))
    return e1, cross(p, e1)
def angle(F, q, e1, e2): w = F(q); return math.atan2(dot(w, e2), dot(w, e1))
def walk(F, pts, e1, e2):                      # total turning of F along a list of points, in turns
    tot, a0 = 0.0, angle(F, pts[0], e1, e2)
    for q in pts[1:]:
        a1 = angle(F, q, e1, e2)
        step = (a1 - a0 + math.pi) % TAU - math.pi
        assert abs(step) < 1.0, "steps too coarse to follow the wind"
        tot, a0 = tot + step, a1
    return tot / TAU
def circle(p, rad, n=360, sense=1):            # loop of angular radius rad round p, anticlockwise from outside
    e1, e2 = frame(p)
    return [tuple(math.cos(rad) * p[i] + math.sin(rad) * (math.cos(sense * TAU * k / n) * e1[i]
            + math.sin(sense * TAU * k / n) * e2[i]) for i in range(3)) for k in range(n + 1)]
def loop_index(F, p, rad=0.02, sense=1): return walk(F, circle(p, rad, sense=sense), *frame(p))
def det_sign(F, p, h=1e-5):                    # linear part of F in p's tangent coordinates
    e1, e2 = frame(p)
    def comp(s, t):
        q = unit(tuple(p[i] + s * e1[i] + t * e2[i] for i in range(3))); w = F(q)
        return dot(w, e1), dot(w, e2)
    (a, c), (a_, c_) = comp(h, 0), comp(-h, 0)
    (b, d), (b_, d_) = comp(0, h), comp(0, -h)
    det = ((a - a_) * (d - d_) - (b - b_) * (c - c_)) / (4 * h * h)
    return 1 if det > 0 else -1
def latlon(r): return 90 - math.acos(r[2]) * DEG, math.atan2(r[1], r[0]) * DEG

s3 = 1 / math.sqrt(3)
zeros = [(sx * s3, sy * s3, sz * s3) for sx in (1, -1) for sy in (1, -1) for sz in (1, -1)]
zeros += [tuple(float(s if i == j else 0) for i in range(3)) for j in range(3) for s in (1, -1)]
rp, hd = unit((0.3, 0.5, 0.8)), 1e-5              # W = -grad p, checked against differences of p
for e in frame(rp):
    ph = [pressure(unit(tuple(rp[i] + s * e[i] for i in range(3)))) for s in (hd, -hd)]
    assert abs((ph[0] - ph[1]) / (2 * hd) + dot(wind(rp), e)) < 1e-6, "wind is not -grad p"
print("calm spot      lat        lon   p hPa  loop  det")
tot1 = tot2 = tot_t = 0
for z in zeros:
    assert math.sqrt(dot(wind(z), wind(z))) < 1e-12, "a listed calm spot is not calm"
    i1, i2 = round(loop_index(wind, z)), det_sign(wind, z)
    assert abs(loop_index(wind, z) - i1) < 1e-9 and i1 == i2, "loop and determinant disagree"
    it = round(loop_index(turned, z)); tot_t += it
    assert it == i1, "a quarter turn changed an index"
    p = pressure(z); kind = "high" if p > 1013.5 else "low" if p < 1012.5 else "col"
    tot1, tot2 = tot1 + i1, tot2 + i2
    print(f"{kind:>9} {latlon(z)[0]:8.4f} {latlon(z)[1]:10.4f} {p:7.2f} {i1:+5d} {i2:+4d}")
nk = [sum(1 for z in zeros if pressure(z) > 1013.5), sum(1 for z in zeros if pressure(z) < 1012.5)]
assert nk == [4, 4], "the map should have 4 highs and 4 lows"
print(f"highs {nk[0]}, lows {nk[1]}, cols {14 - sum(nk)}: {nk[0]} + {nk[1]} - {14 - sum(nk)} = {nk[0] + nk[1] - (14 - sum(nk)):+d}")
print(f"road 1 sum of loop indices          {tot1:+d}")
print(f"road 2 sum of determinant signs     {tot2:+d}")
print(f"quarter-turned wind, sum of loop indices {tot_t:+d}")
print(f"loop radius 0.02 rad = {0.02 * RKM:.1f} km")

ta, tb = 0.75, 0.3                             # the grid is tilted, so no calm spot sits on a cell edge
Q = [(math.cos(ta), -math.sin(ta), 0.0), (math.sin(ta) * math.cos(tb), math.cos(ta) * math.cos(tb),
     -math.sin(tb)), (math.sin(ta) * math.sin(tb), math.cos(ta) * math.sin(tb), math.cos(tb))]
def onsphere(c): return unit(tuple(dot(row, c) for row in Q))
n, m = 9, 12
cells, tot3, found, V, E = 0, 0, 0, set(), set()
for ax in range(3):
    for sg in (1, -1):
        def pt(i, j):                          # grid point (i, j) of this cube face, integers -n..n
            c = [0, 0, 0]; c[ax] = sg * n; c[(ax + 1) % 3] = i; c[(ax + 2) % 3] = j; return tuple(c)
        for i in range(-n, n, 2):
            for j in range(-n, n, 2):
                cor = [pt(i, j), pt(i + 2, j), pt(i + 2, j + 2), pt(i, j + 2), pt(i, j)]
                if sg < 0: cor.reverse()       # keep every cell anticlockwise from outside
                bd = [onsphere(tuple(a + (b - a) * k / m for a, b in zip(cor[e], cor[e + 1])))
                      for e in range(4) for k in range(m)] + [onsphere(cor[0])]
                k = walk(wind, bd, *frame(onsphere(tuple(sum(c[t] for c in cor[:4]) / 4 for t in range(3)))))
                assert abs(k - round(k)) < 1e-9
                cells += 1; tot3 += round(k); found += round(k) != 0
                V.update(cor[:4]); E.update(frozenset(cor[e:e + 2]) for e in range(4))
F = cells
print(f"road 3 cells {cells}, cells holding a calm spot {found}, sum {tot3:+d}")
print(f"road 4 grid V {len(V)}  E {len(E)}  F {F}  V - E + F = {len(V) - len(E) + F}")
assert tot1 == tot2 == tot3 == len(V) - len(E) + F == 2 and found == 14, "the four roads disagree"

poles = [loop_index(east, (0.0, 0.0, s)) for s in (1.0, -1.0)]
assert [round(x) for x in poles] == [1, 1]
ldn = math.radians(90 - 51.5)
print(f"east wind: London {10 * math.sin(ldn):.2f} m/s, pole indices {round(poles[0]):+d} {round(poles[1]):+d}")

hi, col = zeros[0], zeros[12]
print("chart, loop position  " + "".join(f"{30 * k:7d}" for k in range(13)))
for name, z in (("high 35N 45E", hi), ("col North Pole", col)):
    e1, e2 = frame(z); pts = circle(z, 0.02)
    vals = [walk(wind, pts[:30 * k + 1], e1, e2) * 360 for k in range(13)]
    print(f"chart, {name:15}" + "".join(f"{v:7.1f}" for v in vals))

counted = len(zeros); cw = sum(round(loop_index(wind, z, sense=-1)) for z in zeros)
big = loop_index(wind, (0.0, 0.0, 1.0), rad=math.radians(60))
print(f"wrong: every calm spot counted +1     {counted:+d}")
print(f"wrong: loops walked clockwise         {cw:+d}")
print(f"wrong: 60 deg loop round North Pole   {round(big):+d}  (1 col, 2 highs, 2 lows inside)")
assert cw == -2 and round(big) == 3

def tor(u, v): return (math.sin(u), math.sin(v))   # doughnut world: wind -grad(cos u + cos v)
def tor_index(F, u0, v0, r=0.05, k=360):
    t = 0.0; a0 = math.atan2(*reversed(F(u0 + r, v0)))
    for s in range(1, k + 1):
        a1 = math.atan2(*reversed(F(u0 + r * math.cos(TAU * s / k), v0 + r * math.sin(TAU * s / k))))
        t += (a1 - a0 + math.pi) % TAU - math.pi; a0 = a1
    return round(t / TAU)
ti = [tor_index(tor, u, v) for u, v in ((0, 0), (math.pi, math.pi), (0, math.pi), (math.pi, 0))]
nt = 6; tV, tE, tF = set(), set(), 0                 # a 6 by 6 grid glued edge to edge into a doughnut
for i in range(nt):
    for j in range(nt):
        c = [(i, j), ((i + 1) % nt, j), ((i + 1) % nt, (j + 1) % nt), (i, (j + 1) % nt)]
        tV.update(c); tE.update(frozenset((c[e], c[(e + 1) % 4])) for e in range(4)); tF += 1
tchi = len(tV) - len(tE) + tF
print(f"doughnut: indices {ti[0]:+d} {ti[1]:+d} {ti[2]:+d} {ti[3]:+d}, sum {sum(ti)}; grid V {len(tV)} E {len(tE)} F {tF}, V - E + F = {tchi}")
print("doughnut: wind round the tube (1, 0) has speed 1 everywhere, no calm spot")
assert sum(ti) == tchi == 0 and ti == [1, 1, -1, -1]
print("ALL CHECKS PASS")
