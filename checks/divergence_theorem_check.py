# Divergence theorem check, standard library only.  Mesh tank 2 m x 1 m x 1 m centred on the origin,
# water leaves at F = k(x, y, z) m/s.  Road one: flux through the skin.  Road two: divergence inside.
import math

def simpson(f, a, b, n=32):
    h = (b - a) / n
    return h / 3 * sum((1 if j in (0, n) else 4 if j % 2 else 2) * f(a + j * h) for j in range(n + 1))

PI = simpson(lambda t: 4 / (1 + t * t), 0, 1, 200)            # pi, built, not imported
K, HALF, L = 0.01, (1.0, 0.5, 0.5), 1000                       # rate; half-sides (m); L per m^3
even = lambda p: (K * p[0], K * p[1], K * p[2])
ends = lambda p: (K * (p[0] ** 3 + p[0]), K * p[1], K * p[2])  # pipes packed toward both ends
def hose(p):                                                   # 20 L/s poured in at the centre
    r = math.sqrt(p[0] ** 2 + p[1] ** 2 + p[2] ** 2)
    return tuple(0.02 * c / (4 * PI * r ** 3) for c in p)

def div(F, p, h=1e-4):                                         # three difference quotients
    tot = 0.0
    for i in range(3):
        up, dn = list(p), list(p); up[i] += h; dn[i] -= h
        tot += (F(up)[i] - F(dn)[i]) / (2 * h)
    return tot

def face(F, i, s):                                             # outward flux, face x_i = s * half
    j, m = [a for a in range(3) if a != i]
    def pt(u, v):
        p = [0.0] * 3; p[i], p[j], p[m] = s * HALF[i], u, v; return p
    return simpson(lambda u: simpson(lambda v: s * F(pt(u, v))[i], -HALF[m], HALF[m]), -HALF[j], HALF[j])

faces = lambda F: [L * face(F, i, s) for i in range(3) for s in (1, -1)]
inside = lambda F: L * simpson(lambda x: simpson(lambda y: simpson(
    lambda z: div(F, (x, y, z)), -.5, .5, 8), -.5, .5, 8), -1, 1, 8)
def on_sphere(R, ph, th): return (R * math.sin(ph) * math.cos(th), R * math.sin(ph) * math.sin(th), R * math.cos(ph))
def sphere_out(F, R):                    # F . (r_phi x r_theta) = F . R^2 sin(phi) (unit radius)
    g = lambda ph, th: sum(a * b for a, b in zip(F(on_sphere(R, ph, th)), on_sphere(R * R * math.sin(ph), ph, th)))
    return L * simpson(lambda ph: simpson(lambda th: g(ph, th), 0, 2 * PI, 64), 0, PI, 64)
def ball_in(F, R):                       # divergence times the spherical volume factor r^2 sin(phi)
    g = lambda r, ph, th: div(F, on_sphere(r, ph, th)) * r * r * math.sin(ph)
    return L * simpson(lambda r: simpson(lambda ph: simpson(lambda th: g(r, ph, th), 0, 2 * PI, 8), 0, PI, 64), 0, R, 4)

fe, fn, fh = faces(even), faces(ends), faces(hose)
print(f"pi, built by Simpson on 4/(1+t^2): {PI:.12f}")
print(f"even supply, divergence at centre and corner (L/s per m^3): {L * div(even, (0, 0, 0)):.3f} {L * div(even, (1, .5, .5)):.3f}")
print("even supply, face by face (L/s): " + " ".join(f"{n} {v:.3f}" for n, v in zip(["+x", "-x", "+y", "-y", "+z", "-z"], fe)))
print(f"even supply, box: out through faces {sum(fe):.3f} L/s; supply inside {inside(even):.3f} L/s; "
      f"speed at end and top centres {even((1, 0, 0))[0]:.3f} {even((0, 0, .5))[2]:.3f} m/s")
print(f"ends supply, divergence at middle and at an end (L/s per m^3): {L * div(ends, (0, 0, 0)):.3f} {L * div(ends, (1, 0, 0)):.3f}; speed at an end {ends((1, 0, 0))[0]:.3f} m/s")
print(f"ends supply, box: out through faces {sum(fn):.3f} L/s; supply inside {inside(ends):.3f} L/s; face pairs " + " ".join(f"{fn[i] + fn[i + 1]:.3f}" for i in (0, 2, 4)))
for R in (1.0, 2.0):
    print(f"ball R = {R:.0f} m: out through sphere {sphere_out(even, R):.3f} L/s; supply inside {ball_in(even, R):.3f} L/s; 40 pi R^3 = {40 * PI * R ** 3:.3f}")
print(f"break 1, inward normals: {-sum(fe):.3f} L/s")
print(f"break 2, top face left out: {sum(fe) - fe[4]:.3f} L/s against {inside(even):.3f} inside")
print(f"break 3, hose at centre: |divergence| at (0.3, 0.2, -0.1) = {abs(L * div(hose, (.3, .2, -.1))):.3f}; out through faces {sum(fh):.3f} L/s")
tip = lambda p: (180 + 100 * p[0] + 4000 * even(p)[0], 120 - 100 * p[2] - 4000 * even(p)[2])
print("figure, 100 px per m, 4000 px per m/s; arrow tips right %.0f,%.0f top %.0f,%.0f corner %.0f,%.0f" % (*tip((1, 0, 0)), *tip((0, 0, .5)), *tip((1, 0, .5))))
assert abs(sum(fe) - inside(even)) < 1e-6 and abs(sum(fn) - inside(ends)) < 1e-6   # two roads, two fields
assert abs(sum(fn) - 80) < 1e-6                                     # the hand count: 2 x 20 + 4 x 10
assert abs(sphere_out(even, 2) - ball_in(even, 2)) < 1e-3 and abs(ball_in(even, 2) - 320 * PI) < 1e-3  # R = 2
assert abs(sum(fh) - 20) < 1e-3 and abs(div(hose, (.3, .2, -.1))) < 1e-6   # the hose breaks it
print("ALL CHECKS PASS")
