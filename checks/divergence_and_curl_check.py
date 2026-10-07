# Divergence and curl -- the check behind the card.  Standard library only;
# math gives atan2 and pi as primitives, and every sum is written out here.
# Wind (P, Q, R) in m/s at the point x m east, y m north and z m up of a mast.
from math import atan2, pi

def W(x, y, z): return (3 + 0.0003 * (x * x - y * y) + x ** 3 / 400000, 0.0006 * x * y, 0.0)
def G(x, y, z): return (3 + z / 10, 0.0, 0.0)            # second case: a breeze growing with height
def rates(x, y):                                         # road one: the partial derivatives, by hand
    return {"dP/dx": 0.0006 * x + 3 * x * x / 400000, "dQ/dy": 0.0006 * x,
            "dQ/dx": 0.0006 * y, "dP/dy": 0 - 0.0006 * y}
def simpson(g, a, b, n=10):
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, n)))
def box(F, c, li, lj, i=0, j=1):                         # road two, no derivatives: round an li x lj box
    def at(u, v):                                        # the field u along axis i and v along axis j from c
        p = list(c); p[i] += u; p[j] += v
        return F(*p)
    a, b = li / 2, lj / 2
    circ = (simpson(lambda u: at(u, -b)[i] - at(u, b)[i], -a, a)       # along the edges, i then j
            + simpson(lambda v: at(a, v)[j] - at(-a, v)[j], -b, b))
    out = (simpson(lambda u: at(u, b)[j] - at(u, -b)[j], -a, a)        # across the edges, outward
           + simpson(lambda v: at(a, v)[i] - at(-a, v)[i], -b, b))
    return circ, out
def turn(F, c, d, dt=0.01, L=1e-4):                     # a straw of length L along d, carried for dt
    root, tip = F(*c), F(c[0] + L * d[0], c[1] + L * d[1], c[2])
    v = (L * d[0] + (tip[0] - root[0]) * dt, L * d[1] + (tip[1] - root[1]) * dt)
    return (atan2(v[1], v[0]) - atan2(d[1], d[0])) / dt

S, E, res = (40.0, 0.0, 0.0), (0.0, 50.0, 0.0), {}
print("wind P = 3 + 0.0003(x^2 - y^2) + x^3/400000, Q = 0.0006xy, R = 0 m/s; S = (40, 0), E = (0, 50) m")
for name, c in (("S", S), ("E", E)):
    r = rates(c[0], c[1]); res[name] = (r["dP/dx"] + r["dQ/dy"], r["dQ/dx"] - r["dP/dy"], r)
    print(f"{name}: wind ({W(*c)[0]:.3f}, {W(*c)[1]:.3f}); " + ", ".join(f"{k} {v:.3f}" for k, v in r.items()))
    print(f"{name}: div {res[name][0]:.6f} per s, curl {res[name][1]:.6f} per s")
(dS, cS, _), (dE, cE, rE) = res["S"], res["E"]
for l in (40, 20, 10, 5):
    oS, cE_l = box(W, S, l, l)[1] / l ** 2, box(W, E, l, l)[0] / l ** 2
    print(f"side {l:2d} m: S outflow/area {oS:.9f}, gap {oS - dS:.9f}; E circulation/area {cE_l:.9f}")
    assert abs(oS - (dS + l * l / 1600000)) < 1e-12      # road two against road one plus the size term
    assert abs(cE_l - cE) < 1e-12                        # circulation per area against the hand curl
east, north = turn(W, E, (1, 0)), turn(W, E, (0, 1))
print(f"E: straws turn east {east:.6f}, north {north:.6f} rad/s; average {(east + north) / 2:.6f}; "
      f"curl/2 {cE / 2:.6f}; one turn in {2 * pi / (cE / 2):.1f} s")
assert abs((east + north) / 2 - cE / 2) < 1e-6           # the straws spin at half the curl
cG, oG = box(G, (0.0, 0.0, 10.0), 2, 2, 2, 0)            # plane z then x: anticlockwise seen from the north
cL = box(lambda x, y, z: (y / 10, -1.0, 0.0), (20.0, 15.0, 0.0), 40, 30)[0]
print(f"breeze 3 + z/10: curl by hand (0, {1 / 10:.1f}, 0); z-x square circulation/area {cG / 4:.6f}, "
      f"outflow {oG:.6f}; roll {cG / 8:.2f} rad/s")
print(f"line-integrals wind (y/10, -1) N: curl by hand {0 - 1 / 10:.1f} N/m; 40 m x 30 m anticlockwise {cL:.3f} J")
assert abs(cG / 4 - 1 / 10) < 1e-12 and abs(cL - (0 - 1 / 10) * 40 * 30) < 1e-9
print(f"mistake 1, curl read as spin: {cE:.2f} rad/s, one turn in {2 * pi / cE:.1f} s, truly {2 * pi / (cE / 2):.1f} s")
print(f"mistake 2, cross rates added at E: {rE['dQ/dx'] + rE['dP/dy']:.3f} per s, not {cE:.3f}")
print(f"mistake 3, order swapped at E: {rE['dP/dy'] - rE['dQ/dx']:.3f} per s, clockwise, not anticlockwise")
for name, c, cx in (("S", S, 90), ("E", E, 270)):
    w0, pts = W(*c), []
    for hx, hy in ((10, 0), (10, 10), (0, 10), (-10, 10), (-10, 0), (-10, -10), (0, -10), (10, -10)):
        w = W(c[0] + hx, c[1] + hy, 0.0)
        pts.append(f"({cx + 5 * hx},{120 - 5 * hy})->({cx + 5 * hx + 80 * (w[0] - w0[0]):.0f},{120 - 5 * hy - 80 * (w[1] - w0[1]):.0f})")
    print(f"figure, {name}, 5 units per m, 80 per m/s:", " ".join(pts))
print("ALL CHECKS PASS")
