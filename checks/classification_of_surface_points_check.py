# Point types -- the check behind the card.  Standard library only.
# A pasta ring modelled as a torus: the tube's centre line is a circle of
# radius b = 4 mm, the tube has radius a = 1.5 mm.  Each point is sorted by the
# signs of its two principal curvatures, found three ways: the closed form, the
# shape operator from finite differences, and slices in 360 directions.
import math

B, A = 4.0, 1.5                              # ring radius and tube radius (mm)
TOL = 1e-3                                   # a curvature under 0.001 per mm counts as zero

def sub(p, q): return (p[0] - q[0], p[1] - q[1], p[2] - q[2])
def dot(p, q): return p[0] * q[0] + p[1] * q[1] + p[2] * q[2]
def cross(p, q): return (p[1] * q[2] - p[2] * q[1], p[2] * q[0] - p[0] * q[2], p[0] * q[1] - p[1] * q[0])
def scale(p, s): return (p[0] * s, p[1] * s, p[2] * s)

def torus(u, v):                             # u: round the ring, v: round the tube, 0 = outer edge
    w = B + A * math.cos(v)
    return (w * math.cos(u), w * math.sin(u), A * math.sin(v))
def torus_in(u, v): return (B * math.cos(u), B * math.sin(u), 0.0)   # a point inside the dough
def rigatoni(u, v): return (7.5 * math.cos(u), 7.5 * math.sin(u), v)
def rigatoni_in(u, v): return (0.0, 0.0, v)
def lasagna(u, v): return (u, v, 0.0)
def lasagna_in(u, v): return (u, v, -1.0)

def kind(k1, k2):                            # the sorting rule of the card
    z1, z2 = abs(k1) < TOL, abs(k2) < TOL
    if z1 and z2: return "flat"
    if z1 or z2: return "trough"
    return "dome" if k1 * k2 > 0 else "saddle"

def frame(patch, inside, u, v, h=1e-4):      # finite-difference derivatives and the inward normal
    p = patch(u, v)
    ru = scale(sub(patch(u + h, v), patch(u - h, v)), 1 / (2 * h))
    rv = scale(sub(patch(u, v + h), patch(u, v - h)), 1 / (2 * h))
    ruu = scale(sub(sub(patch(u + h, v), p), sub(p, patch(u - h, v))), 1 / (h * h))
    rvv = scale(sub(sub(patch(u, v + h), p), sub(p, patch(u, v - h))), 1 / (h * h))
    ruv = scale(sub(sub(patch(u + h, v + h), patch(u + h, v - h)),
                    sub(patch(u - h, v + h), patch(u - h, v - h))), 1 / (4 * h * h))
    n = cross(ru, rv)
    n = scale(n, 1 / math.sqrt(dot(n, n)))
    if dot(n, sub(inside(u, v), p)) < 0: n = scale(n, -1)    # point n into the dough
    return p, ru, rv, ruu, ruv, rvv, n

def shape_operator(patch, inside, u, v):     # road 2: E, F, G and L, M, N, then the eigenvalues
    p, ru, rv, ruu, ruv, rvv, n = frame(patch, inside, u, v)
    E, F, G = dot(ru, ru), dot(ru, rv), dot(rv, rv)
    L, M, N = dot(ruu, n), dot(ruv, n), dot(rvv, n)
    K = (L * N - M * M) / (E * G - F * F)
    H = (E * N - 2 * F * M + G * L) / (2 * (E * G - F * F))
    s = math.sqrt(max(H * H - K, 0.0))
    return H + s, H - s, K, H, L * N - M * M

def slices(u, v, t):                         # road 3: height above the tangent plane in 360 directions
    p, ru, rv, _, _, _, n = frame(torus, torus_in, u, v)
    eu, ev = math.sqrt(dot(ru, ru)), math.sqrt(dot(rv, rv))
    kn = []
    for d in range(360):
        th = math.radians(d)                 # 0 degrees: round the ring; 90: round the tube
        q = torus(u + t * math.cos(th) / eu, v + t * math.sin(th) / ev)
        h = dot(sub(q, p), n)
        kn.append(2 * h / (dot(sub(q, p), sub(q, p)) - h * h))
    return kn

def closed(v):                               # road 1: tube 1/a, ring cos v / (B + a cos v)
    return 1 / A, math.cos(v) / (B + A * math.cos(v))

f6 = lambda x: f"{0.0 if abs(x) < 5e-7 else x:.6f}"
print("v (deg)  tube k1    ring k2    K (1/mm^2)  H (1/mm)   type")
for deg in (0, 30, 60, 90, 120, 150, 180):
    v = math.radians(deg)
    k1, k2 = closed(v)
    s1, s2, K, H, LNM = shape_operator(torus, torus_in, 0.0, v)
    assert abs(s1 - max(k1, k2)) < 1e-6 and abs(s2 - min(k1, k2)) < 1e-6   # road 2 against road 1
    assert abs(K - k1 * k2) < 1e-6 and kind(s1, s2) == kind(k1, k2)
    kn = slices(0.0, v, 1e-3)
    assert abs(max(kn) - max(k1, k2)) < 1e-3 and abs(min(kn) - min(k1, k2)) < 1e-3  # road 3
    assert (LNM > 1e-9) == (k1 * k2 > 1e-9)              # sign of K needs only L, M, N
    assert kind(s1, s2) == ("dome" if deg < 90 else "trough" if deg == 90 else "saddle")  # outer half dome
    print(f"{deg:>7}  {f6(k1):>9}  {f6(k2):>9}  {f6(k1 * k2):>10}  {f6((k1 + k2) / 2):>9}  {kind(k1, k2)}")

for deg in (0, 180, 90):                     # the three named points, slice by slice
    v = math.radians(deg)
    k1, k2 = closed(v)
    errs = []
    for t in (1e-2, 1e-3):
        kn = slices(0.0, v, t)
        euler = [k2 * math.cos(math.radians(d)) ** 2 + k1 * math.sin(math.radians(d)) ** 2 for d in range(360)]
        errs.append(max(abs(kn[d] - euler[d]) for d in range(360)))
    kn = slices(0.0, v, 1e-3)
    changes = sum(1 for d in range(360) if kn[d] * kn[(d + 1) % 360] < 0)
    print(f"v = {deg:>3}: slice curvature from {f6(min(kn))} to {f6(max(kn))} per mm, "
          f"{changes} sign changes, Euler error {errs[0]:.8f} at step 0.01, {errs[1]:.8f} at 0.001")
    assert errs[1] < errs[0] / 5                       # the slices converge as the step shrinks
    assert changes == {0: 0, 180: 4, 90: 0}[deg]

print(f"top of the ring, unrounded: ring k2 = {closed(math.pi / 2)[1]:.1e} per mm by the closed form, not exactly 0")
k1, k2 = closed(math.pi)                    # saddle: directions where the slice is straight
ang = math.degrees(math.atan(math.sqrt(-k1 / k2)))
kn = slices(0.0, math.pi, 1e-3)              # road 3 locates them on its own; 90 is the tube direction
cuts = [d + 0.5 for d in range(360) if kn[d] * kn[(d + 1) % 360] < 0]
print(f"inner edge: straight slices at {ang:.2f} degrees either side of the tube direction; slices change sign at",
      ", ".join(f"{c:.1f}" for c in cuts), "degrees")
assert len(cuts) == 4 and all(abs(c - w) < 1 for c, w in zip(cuts, (90 - ang, 90 + ang, 270 - ang, 270 + ang)))
gap = min(closed(math.radians(d))[0] - closed(math.radians(d))[1] for d in range(360))
print(f"no umbilic on the ring: k1 - k2 is at least {f6(gap)} per mm, at the outer edge")
assert gap > TOL and abs(gap - (1 / A - 1 / (B + A))) < 1e-12

share = 0.5 + A / (math.pi * B)              # dome share of the area, closed form
n, dome_area, area, dome_K, all_K = 3600, 0.0, 0.0, 0.0, 0.0   # against a midpoint sum round the tube
for i in range(n):
    v = (i + 0.5) * 2 * math.pi / n
    dA = 2 * math.pi * A * (B + A * math.cos(v)) * 2 * math.pi / n   # a whole band round the ring
    k1, k2 = closed(v)
    area += dA; all_K += k1 * k2 * dA
    if k1 * k2 > 0: dome_area += dA; dome_K += k1 * k2 * dA
print(f"dome share of the pasta's surface: {share:.6f} by formula, {dome_area / area:.6f} by sum")
print(f"total K by sum: dome part {dome_K:.5f}, saddle part {all_K - dome_K:.5f}, whole ring {f6(all_K)}; 4 pi = {4 * math.pi:.5f}")
assert abs(dome_area / area - share) < 1e-6 and abs(dome_K - 4 * math.pi) < 1e-5 and abs(all_K) < 1e-9
print(f"dome {100 * share:.1f}% and saddle {100 - 100 * share:.1f}% of the surface")
far = max(math.sqrt(dot(torus(0.0, math.radians(d)), torus(0.0, math.radians(d)))) for d in range(360))
print(f"farthest from the centre: {far:.1f} mm, and 1/{far:.1f} = {f6(1 / far)} per mm")
assert abs(1 / far - closed(0.0)[1]) < 1e-12 and closed(0.0)[0] > 1 / far

for name, patch, inside in (("rigatoni", rigatoni, rigatoni_in), ("lasagna", lasagna, lasagna_in)):
    s1, s2, K, H, _ = shape_operator(patch, inside, 0.3, 0.7)
    print(f"{name}{' (radius 7.5 mm)' if name == 'rigatoni' else ''}: k1 {f6(s1)}, k2 {f6(s2)} per mm, type {kind(s1, s2)}")
    assert kind(s1, s2) == ("trough" if name == "rigatoni" else "flat")

print(f"mistake, sort by H: inner edge H = {f6(sum(closed(math.pi)) / 2)} per mm, positive, yet a saddle")
k1, k2 = closed(0.0)
print(f"mistake, flip the normal: outer edge k1 = {f6(-k1)}, k2 = {f6(-k2)}, K still {f6(k1 * k2)}")
for name, f in (("x^4 + y^4", lambda x, y: x ** 4 + y ** 4), ("x^3 - 3xy^2", lambda x, y: x ** 3 - 3 * x * y * y)):
    hs = [f(0.5 * math.cos(math.radians(d + 0.5)), 0.5 * math.sin(math.radians(d + 0.5))) for d in range(360)]
    ch = sum(1 for d in range(360) if hs[d] * hs[(d + 1) % 360] < 0)
    hxx = (f(1e-3, 0) - 2 * f(0, 0) + f(-1e-3, 0)) / 1e-6
    print(f"mistake, trust a flat point: {name} has curvatures 0, 0 (f_xx {hxx:.4f}), {ch} sign changes")
    assert abs(hxx) < 1e-5 and ch == {"x^4 + y^4": 0, "x^3 - 3xy^2": 6}[name]
print(f"figure, tube centres at x = -{B:.3f} and {B:.3f} mm, tube radius {A:.3f} mm, troughs at z = +-{A:.3f} mm")
print(f"ring {2 * (B + A):.1f} mm across, hole {2 * (B - A):.1f} mm across")
print("ALL CHECKS PASS")
