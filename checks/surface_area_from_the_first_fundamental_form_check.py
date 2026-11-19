# Surface area from the first fundamental form -- the check behind the card.
# Standard library only.  A stadium roof: a half dome over the east end and a
# saddle over the middle.  Area = double integral of sqrt(EG - F^2), done by
# Simpson's rule written out, in two charts per panel; then a flat-triangle mesh
# that never forms E, F or G; then the dome's closed form.
import math

def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def efg(ru, rv): return dot(ru, ru), dot(ru, rv), dot(rv, rv)
def stretch(ru, rv):                         # sqrt(EG - F^2): m^2 of roof per unit of chart
    E, F, G = efg(ru, rv)
    return math.sqrt(E * G - F * F)

def simpson2(chart, a, b, c, d, n):          # Simpson's rule on an n-by-n grid, n even
    hu, hv, s = (b - a) / n, (d - c) / n, 0.0
    w = [1 if i in (0, n) else (4 if i % 2 else 2) for i in range(n + 1)]
    for i in range(n + 1):
        for j in range(n + 1):
            s += w[i] * w[j] * stretch(*chart(a + i * hu, c + j * hv))
    return s * hu * hv / 9

R, H = 60.0, 12.0                            # dome: sphere radius, rise of the cap (m)
B = math.sqrt(2 * R * H - H * H)             # radius of the dome's footprint: 36 m
PHI0 = math.acos((R - H) / R)                # polar angle at the dome's rim
SR, LX, LY = 60.0, 30.0, 36.0                # saddle radius a: z = 30 + (x^2 - y^2)/(2a), |x| <= 30, |y| <= 36
SHEET = 0.0006 * 8960                        # kg per m^2 of 0.6 mm copper sheet

def sphere(p, t):                            # chart 1: polar angle p, longitude t
    return ((R * math.cos(p) * math.cos(t), R * math.cos(p) * math.sin(t), -R * math.sin(p)),
            (-R * math.sin(p) * math.sin(t), R * math.sin(p) * math.cos(t), 0.0))
def plan_polar(rho, t):                      # chart 2: distance rho and angle t on the plan
    s = math.sqrt(R * R - rho * rho)
    return (math.cos(t), math.sin(t), -rho / s), (-rho * math.sin(t), rho * math.cos(t), 0.0)
def saddle(x, y):                            # chart 1: plan coordinates x, y
    return (1.0, 0.0, x / SR), (0.0, 1.0, -y / SR)
def cubic(s, t):                             # chart 2: x = 15(s + s^3), y = 18(t + t^3)
    x, y = LX * (s + s ** 3) / 2, LY * (t + t ** 3) / 2
    xs, yt = LX * (1 + 3 * s * s) / 2, LY * (1 + 3 * t * t) / 2
    return (xs, 0.0, xs * x / SR), (0.0, yt, -yt * y / SR)
def folded(s, y):                            # a chart that doubles back: x = 30(2s^2 - 1)
    x, xs = LX * (2 * s * s - 1), 4 * LX * s
    return (xs, 0.0, xs * x / SR), (0.0, 1.0, -y / SR)
def roof(x, y): return (x, y, 30 + (x * x - y * y) / (2 * SR))

def mesh(n):                                 # flat triangles pinned to the saddle: no E, F, G
    total, hx, hy = 0.0, 2 * LX / n, 2 * LY / n
    for i in range(n):
        for j in range(n):
            x, y = -LX + i * hx, -LY + j * hy
            p, q, r, s = roof(x, y), roof(x + hx, y), roof(x + hx, y + hy), roof(x, y + hy)
            for a, b, c in ((p, q, r), (p, r, s)):
                u = tuple(b[k] - a[k] for k in range(3)); v = tuple(c[k] - a[k] for k in range(3))
                total += math.sqrt(dot(cross(u, v), cross(u, v))) / 2
    return total

f6 = lambda v: f"{v:.6f}"
print("dome, footprint radius m", f6(B))
print("dome, rim polar angle rad", f6(PHI0), "deg", f6(math.degrees(PHI0)), "cos", f6(math.cos(PHI0)))
d_closed = math.pi * R * H                   # half of Archimedes' 2 pi R h
d1 = simpson2(sphere, 0.0, PHI0, -math.pi / 2, math.pi / 2, 100)
d2 = simpson2(plan_polar, 0.0, B, -math.pi / 2, math.pi / 2, 100)
print("dome area, closed form pi R h", f6(d_closed))
print("dome area, chart 1 (sphere)  ", f6(d1))
print("dome area, chart 2 (plan)    ", f6(d2))
d_plan = math.pi * B * B / 2
print("dome plan area", f6(d_plan), "ratio", f6(d_closed / d_plan))
assert abs(d1 - d_closed) < 1e-6
assert abs(d2 - d_closed) < 1e-3

ru, rv = saddle(30.0, 36.0)
E, F, G = efg(ru, rv)
print("saddle corner (30, 36): E", f6(E), "F", f6(F), "G", f6(G))
print("saddle corner: EG", f6(E * G), "F^2", f6(F * F), "EG-F^2", f6(E * G - F * F), "stretch", f6(stretch(ru, rv)))
print("saddle corner: |r_x x r_y|", f6(math.sqrt(dot(cross(ru, rv), cross(ru, rv)))))
assert abs(math.sqrt(dot(cross(ru, rv), cross(ru, rv))) - stretch(ru, rv)) < 1e-12
cu, cv = cubic(1.0, 1.0)                     # same corner in chart 2
E2, F2, G2 = efg(cu, cv)
print("same corner, chart 2: E", f6(E2), "F", f6(F2), "G", f6(G2), "stretch", f6(stretch(cu, cv)))
print("chart 2 stretch / chart 1 stretch", f6(stretch(cu, cv) / stretch(ru, rv)), "Jacobian x_s y_t", f6(60.0 * 72.0))
s1 = simpson2(saddle, -LX, LX, -LY, LY, 200)
s2 = simpson2(cubic, -1.0, 1.0, -1.0, 1.0, 200)
print("saddle area, chart 1 (plan x, y)", f6(s1))
print("saddle area, chart 2 (cubic s, t)", f6(s2))
assert abs(s1 - s2) < 1e-4
m1, m2 = mesh(30), mesh(60)
print("saddle area, mesh 30 x 30", f6(m1), "error", f6(m1 - s1))
print("saddle area, mesh 60 x 60", f6(m2), "error", f6(m2 - s1), "ratio", f6((m1 - s1) / (m2 - s1)))
assert abs(m2 - s1) < abs(m1 - s1) / 3.5
s_plan = 2 * LX * 2 * LY
print("saddle plan area", f6(s_plan), "ratio", f6(s1 / s_plan))

total = d_closed + s1
print("copper, m^2", f6(total), "kg at 5.376 kg/m^2", f6(total * SHEET))
print("plan m^2", f6(d_plan + s_plan), "short by", f6(total - d_plan - s_plan))
no_f = simpson2(lambda x, y: ((math.sqrt(efg(*saddle(x, y))[0]), 0, 0), (0, math.sqrt(efg(*saddle(x, y))[2]), 0)), -LX, LX, -LY, LY, 200)
no_sin = R * R * PHI0 * math.pi              # G taken as R^2: the sin(p)^2 forgotten
a60 = (0.5, 0.0, 0.0); b60 = (0.25, 0.5 * math.sqrt(3) / 2, 0.0)   # diamond shingle, 0.5 m sides at 60 deg
E, F, G = efg(a60, b60)
print("diamond shingle: E", f6(E), "F", f6(F), "G", f6(G), "area", f6(stretch(a60, b60)), "sqrt(EG)", f6(math.sqrt(E * G)),
      "ratio", f6(math.sqrt(E * G) / stretch(a60, b60)))
assert abs(stretch(a60, b60) - 0.25 * math.sin(math.pi / 3)) < 1e-12
fold = simpson2(folded, -1.0, 1.0, -LY, LY, 200)
print("breaks: plan area for saddle", f6(s_plan))
print("breaks: drop F^2, sqrt(EG)", f6(no_f), "excess", f6(no_f - s1))
print("breaks: dome with G = R^2", f6(no_sin), "times", f6(no_sin / d_closed))
print("breaks: folded chart", f6(fold), "times", f6(fold / s1))
assert no_f > s1 + 1.0
assert abs(fold / s1 - 2.0) < 1e-6

print("try: saddle a = 90", f6(simpson2(lambda x, y: ((1.0, 0.0, x / 90), (0.0, 1.0, -y / 90)), -LX, LX, -LY, LY, 200)))
print("try: dome rise 18 m", f6(math.pi * R * 18), "footprint radius", f6(math.sqrt(2 * R * 18 - 18 * 18)))
print("try: Simpson n = 4", f6(simpson2(saddle, -LX, LX, -LY, LY, 4)))
print("try: mesh 6 x 6", f6(mesh(6)))
print("figure, saddle plan x", f6(-LX), f6(LX), "y", f6(-LY), f6(LY), "dome centre x", f6(LX), "radius", f6(B))
print("ALL CHECKS PASS")
