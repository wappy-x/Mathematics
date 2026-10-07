# Trig identities -- the check behind the card.  A 30 m main boom raised 40 deg,
# a 10 m jib hinged at its head and bent 30 deg further up.  Road 1: the built-in
# sine as a calculator gives it, sin 30 and cos 30 exact, and the identities.
# Road 2: no sine at all; directions come from halving angles, booms add as arrows.
from math import sin, cos, sqrt, radians
L1, L2, TH, BEND = 30.0, 10.0, 40.0, 30.0
S30, C30 = 0.5, sqrt(3) / 2                        # exact: half an equilateral triangle

def single_sine(l1, l2, sb, cb):                   # P sin t + Q cos t = R sin(t + phi)
    p, q = l1 + l2 * cb, l2 * sb
    r = sqrt(l1 * l1 + l2 * l2 + 2 * l1 * l2 * cb)  # P^2 + Q^2, once sin^2 + cos^2 = 1
    lo, hi = 0.0, 90.0                             # phi: the angle whose sine is Q / R
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if sin(radians(mid)) < q / r else (lo, mid)
    return p, q, r, lo
def direction(up):                                 # road 2: halve the angle 60 times
    lo, hi, a_lo, a_hi = (1.0, 0.0), (0.0, 1.0), 0.0, 90.0
    for _ in range(60):
        x, y = lo[0] + hi[0], lo[1] + hi[1]        # a rhombus diagonal halves the angle
        n = sqrt(x * x + y * y)
        mid, a = (x / n, y / n), (a_lo + a_hi) / 2
        lo, hi, a_lo, a_hi = (mid, hi, a, a_hi) if up(mid, a) else (lo, mid, a_lo, a)
    return mid, a
def unit(deg): return direction(lambda v, a: a < deg)[0]
def at(p, m, u): return (p[0] + m * u[0], p[1] + m * u[1])
def svg(p): return f"({40 + 7 * p[0]:.2f}, {222 - 7 * p[1]:.2f})"

s, c = sin(radians(TH)), cos(radians(TH))         # road 1: sin 40, cos 40 built in
s70, c70 = s * C30 + c * S30, c * C30 - s * S30    # the addition formulas
h1, x1 = L1 * s + L2 * s70, L1 * c + L2 * c70
p, q, r, phi = single_sine(L1, L2, S30, C30)
u40, u70 = unit(TH), unit(TH + BEND)              # road 2: arrows on a grid
kn = at((0, 0), L1, u40)
tip = at(kn, L2, u70)
r2 = sqrt(tip[0] * tip[0] + tip[1] * tip[1])
phi2 = direction(lambda v, a: v[1] * tip[0] < tip[1] * v[0])[1] - TH  # steer by slope
dbl, half, h80, h20 = 2 * s * c, sqrt((1 - c) / 2), L1 * unit(2 * TH)[1], L1 * unit(TH / 2)[1]
print(f"sin 40 = {s:.6f}, cos 40 = {c:.6f}; squares add to {s * s + c * c:.6f}")
print(f"road 1, addition formulas with sin 30 = {S30:.6f}, cos 30 = {C30:.6f}: sin 70 = {s70:.6f}, cos 70 = {c70:.6f}")
print(f"road 1: height {L1 * s:.4f} + {L2 * s70:.4f} = {h1:.4f} m; reach {L1 * c:.4f} + {L2 * c70:.4f} = {x1:.4f} m")
print(f"road 2, arrows on a grid: knuckle ({kn[0]:.4f}, {kn[1]:.4f}), tip ({tip[0]:.4f}, {tip[1]:.4f})")
print(f"single sine: P = {p:.4f}, Q = {q:.4f}; R = {r:.4f} m, by the distance formula {r2:.4f} m")
print(f"phi = {phi:.4f} deg by root finding, {phi2:.4f} deg from the tip's direction")
print(f"check: {r:.4f} x sin {TH + phi:.4f} = {r * sin(radians(TH + phi)):.4f} m; highest tip {r:.4f} m at boom angle {90 - phi:.4f} deg")
print(f"double: boom at 80 deg, 30 x 2 sin 40 cos 40 = {L1 * dbl:.4f} m; on the grid {h80:.4f} m")
print(f"half: boom at 20 deg, 30 x root((1 - cos 40)/2) = {L1 * half:.4f} m; on the grid {h20:.4f} m")
print(f"mistake 1, sin 70 as sin 40 + sin 30 = {s + S30:.6f}: tip at {L1 * s + L2 * (s + S30):.4f} m")
print(f"mistake 2, plus in the cosine formula: cos 70 as {c * C30 + s * S30:.6f}, reach {L1 * c + L2 * (c * C30 + s * S30):.4f} m")
print(f"mistake 3, twice the angle read as twice the height: {2 * L1 * s:.4f} m; mistake 4, R as {L1 + L2:.0f} m")
(_, _, r0, p0), (_, _, r3, p3) = single_sine(L1, L2, 0.0, 1.0), single_sine(L1, L1, S30, C30)
print(f"try: bend 0 gives R {r0:.4f}, phi {p0:.4f}; jib 30 m gives R {r3:.4f}, phi {p3:.4f}")
print(f"figure, 1 m = 7 units: pivot {svg((0, 0))}, knuckle {svg(kn)}, tip {svg(tip)}, foot {svg((tip[0], 0))}")
print(f"figure, arcs: 40 deg {svg((4, 0))} to {svg(at((0, 0), 4, u40))}; phi {svg(at((0, 0), 10, u40))} to "
      f"{svg(at((0, 0), 10 / r2, tip))}; bend {svg(at(kn, 3, u40))} to {svg(at(kn, 3, u70))}; guide to {svg(at(kn, 4, u40))}")
assert abs(h1 - tip[1]) < 1e-9 and abs(x1 - tip[0]) < 1e-9            # sine and cosine addition
assert abs(r - r2) < 1e-9 and abs(phi - phi2) < 1e-9                   # R and phi, two roads
assert abs(r * sin(radians(TH + phi)) - tip[1]) < 1e-9                 # the single sine
assert abs(L1 * dbl - h80) < 1e-9 and abs(L1 * half - h20) < 1e-9      # double and half angle
print("ALL CHECKS PASS")
