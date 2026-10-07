# Stokes' theorem -- the check behind the card.  Standard library only.  A bowl: the lower half of a
# sphere of radius 2 m, rim at height 0.  Wind circles the rim anticlockwise seen from above.
# Road one: circulation round the rim.  Road two: difference-quotient curl, its flux through the bowl.
import math

def simpson(f, a, b, n=64):
    h = (b - a) / n
    return h / 3 * sum((1 if j in (0, n) else 4 if j % 2 else 2) * f(a + j * h) for j in range(n + 1))

PI = simpson(lambda t: 4 / (1 + t * t), 0, 1, 200)             # pi, built, not imported
R, W = 2.0, 0.5                                                 # bowl radius (m); swirl rate (per second)
swirl = lambda p: (-W * p[1], W * p[0], 0.0)                    # 1 m/s at the rim, same at every depth
fading = lambda p: tuple((1 + p[2] / R) * c for c in swirl(p))    # the same swirl, dying away to the bottom
drain = lambda p: (-2 * p[1] / (p[0] ** 2 + p[1] ** 2), 2 * p[0] / (p[0] ** 2 + p[1] ** 2), 0.0)
dot = lambda a, b: sum(x * y for x, y in zip(a, b))
cross = lambda a, b: (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
nudge = lambda p, j, h: [p[k] + h * (k == j) for k in range(3)]
def curl(F, p, h=1e-4):                                         # d[i][j]: rate of F_i along axis j
    d = [[(F(nudge(p, j, h))[i] - F(nudge(p, j, -h))[i]) / (2 * h) for j in range(3)] for i in range(3)]
    return (d[2][1] - d[1][2], d[0][2] - d[2][0], d[1][0] - d[0][1])
def rate(f, t, h=1e-5):                                         # velocity of a moving point
    return [(a - b) / (2 * h) for a, b in zip(f(t + h), f(t - h))]
def rim(F, turn=1):                                             # road one: add F . dr round the rim
    c = lambda t: (R * math.cos(t), turn * R * math.sin(t), 0.0)
    return simpson(lambda t: dot(F(c(t)), rate(c, t)), 0, 2 * PI)
def flux(G, chart, u0, u1, v0, v1, n=128):                      # G . (r_u x r_v), added over the chart
    g = lambda u, v: dot(G(chart(u, v)), cross(rate(lambda s: chart(s, v), u), rate(lambda s: chart(u, s), v)))
    return simpson(lambda u: simpson(lambda v: g(u, v), v0, v1, n), u0, u1, n)
bowl = lambda th, ph: (R * math.sin(ph) * math.cos(th), R * math.sin(ph) * math.sin(th), R * math.cos(ph))
lid = lambda r, th: (r * math.cos(th), r * math.sin(th), 0.0)
bowl_curl = lambda F, n=128: flux(lambda p: curl(F, p), bowl, 0, 2 * PI, PI / 2, PI, n)
lid_curl = lambda F: flux(lambda p: curl(F, p), lid, 0, R, 0, 2 * PI)
v3 = lambda v: "(" + ", ".join(f"{abs(x) if abs(x) < 5e-10 else x:.3f}" for x in v) + ")"
S2 = math.sqrt(2)
hand = 2 * PI * W * R ** 2
print(f"pi, built by Simpson on 4/(1+t^2): {PI:.12f}")
print(f"swirl: speed at the rim {math.sqrt(dot(swirl((2, 0, 0)), swirl((2, 0, 0)))):.3f} m/s; curl at (2, 0, 0) and (1, 0.5, -1): "
      f"{v3(curl(swirl, (2, 0, 0)))} {v3(curl(swirl, (1, .5, -1)))}")
print(f"curl of fading at rim, halfway down, bottom: {v3(curl(fading, (2, 0, 0)))} {v3(curl(fading, (S2, 0, -S2)))} {v3(curl(fading, (0, 0, -2)))}")
for name, F in (("swirl", swirl), ("fading", fading)):
    print(f"{name}: rim circulation {rim(F):.6f}; curl flux, bowl {bowl_curl(F):.6f}; lid {lid_curl(F):.6f}")
print(f"by hand, 2 pi w R^2 = {hand:.9f}")
for n in (2, 4, 8, 16):
    print(f"fading, bowl with {n:2d} Simpson strips a side: {bowl_curl(fading, n):.9f}, error {abs(bowl_curl(fading, n) - hand):.9f}")
out = flux(lambda p: curl(fading, p), lambda ph, th: bowl(th, ph), PI / 2, PI, 0, 2 * PI)
area = flux(lambda p: tuple(-c / R for c in p), bowl, 0, 2 * PI, PI / 2, PI)
print(f"break 1, normal out of the bowl, rim unchanged: {out:.3f} against {rim(fading):.3f}")
size = math.sqrt(dot(curl(swirl, (1, 1, -1)), curl(swirl, (1, 1, -1))))
print(f"break 2, curl size times bowl area: {size:.3f} x {area:.3f} = {size * area:.3f}")
print(f"break 3, flux of the wind itself through the bowl: {abs(flux(swirl, bowl, 0, 2 * PI, PI / 2, PI)):.3f}")
print(f"break 4, drain wind: rim circulation {rim(drain):.3f}; curl at (1, 0.5, -1) {v3(curl(drain, (1, .5, -1)))}")
tip = lambda p, c: f"{180 + 60 * p[0] + 50 * c[0]:.0f},{60 - 60 * p[2] - 50 * c[2]:.0f}"
pts = [(2, 0, 0), (-2, 0, 0), (S2, 0, -S2), (-S2, 0, -S2), (0, 0, 0)]
print("figure, 60 px per m, 50 px per 1/s; curl tips " + " ".join(tip(p, curl(fading, p)) for p in pts))
assert abs(rim(fading) - bowl_curl(fading)) < 1e-6 and abs(rim(swirl) - bowl_curl(swirl)) < 1e-6  # two roads
assert abs(bowl_curl(fading) - hand) < 1e-6                     # the hand count on the curved sheet
assert abs(lid_curl(fading) - rim(fading)) < 1e-6 and rim(fading, -1) < 0   # Green's flat case; turn matters
assert abs(rim(drain) - hand) < 1e-6 and abs(curl(drain, (1, .5, -1))[2]) < 1e-6   # the drain breaks it
print("ALL CHECKS PASS")
