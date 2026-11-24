# Hilbert's axioms -- the check behind the card.  Nothing is imported.
# Euclid I.1: A = (0, 0), B = (4, 0), a circle of radius 4 cm about each.
# The crossing is found by subtracting the circle equations and by bisection
# along circle A's arc; the rational plane is searched; Pasch is tested twice.
R, D, A, B = 4.0, (1.0, 0.0), (0.0, 0.0), (4.0, 0.0)

def dist(p, q):
    return ((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2) ** 0.5

def bisect(r, d):                  # P on circle A's upper arc, from (0, r) to (r, 0)
    lo, hi = 0.0, r                # P starts outside circle B and ends inside it
    for _ in range(60):
        mid = (lo + hi) / 2
        if dist((mid, (r * r - mid * mid) ** 0.5), (d, 0.0)) > r: lo = mid
        else: hi = mid
    return lo, (r * r - lo * lo) ** 0.5

def hits(n, qmax):                 # whole p, q with p * p == n * q * q
    return [(p, q) for q in range(1, qmax + 1) for p in [round((n * q * q) ** 0.5)] if p * p == n * q * q]

def meet(u, p0, p1):               # line D + t u against segment p0 + s (p1 - p0)
    ex, ey, bx, by = p1[0] - p0[0], p1[1] - p0[1], p0[0] - D[0], p0[1] - D[1]
    det = ex * u[1] - u[0] * ey
    t, s = (ex * by - bx * ey) / det, (u[0] * by - u[1] * bx) / det
    return s, (D[0] + t * u[0], D[1] + t * u[1])

x1, yy = R / 2, R * R - (R / 2) ** 2               # road one: x = d/2, y*y = r*r - x*x
y1, (x2, y2) = yy ** 0.5, bisect(R, 4.0)           # road two: bisection
C = (x1, y1)
print(f"Hilbert's groups: connection 7, order 5, parallels 1, congruence 6, continuity 1, total {7 + 5 + 1 + 6 + 1}")
print(f"road one, subtract the equations: x = {x1:.6f}, y = {y1:.6f}, y*y = {yy:.6f}")
print(f"road two, bisection along circle A's arc: x = {x2:.6f}, y = {y2:.6f}")
print(f"rational plane, whole p, q up to 1000 with p*p = 12*q*q: {len(hits(12, 1000))} found")
q = min(range(1, 31), key=lambda q: abs(round(q * y1) ** 2 - 12 * q * q) / (q * q))
p = round(q * y1)
print(f"closest fraction with q up to 30: {p}/{q} = {p / q:.6f}, squared {p * p / (q * q):.6f}")
ctl = hits(16, 5)[0]                               # radius 5, centres 6 apart: y*y = 25 - 9
print(f"control, radius 5, centres 6 apart: y*y = {25 - 9}, rational crossing (3, {ctl[0] // ctl[1]})")
sides = {"AB": (A, B), "BC": (B, C), "CA": (C, A)}
exits = []
for u in [(1, 1), (-1, 2)]:
    out = {n: meet(u, *e) for n, e in sides.items() if n != "AB"}
    leave = [n for n, (s, _) in out.items() if 0 < s < 1]
    side = lambda v: u[0] * (v[1] - D[1]) - u[1] * (v[0] - D[0])   # the sign test; zero on the line
    sgn = {n: side(v) > 0 for n, v in zip("ABC", (A, B, C))}
    by_sign = [n for n in ("BC", "CA") if sgn[n[0]] != sgn[n[1]]]
    pt, (p0, p1) = out[leave[0]][1], sides[leave[0]]
    exits.append(pt)
    print(f"line through D (1, 0) heading {u}: leaves through {leave[0]} at ({pt[0]:.3f}, {pt[1]:.3f});"
          f" signs at A, B, C: {''.join('+' if sgn[n] else '-' for n in 'ABC')}")
    assert leave == by_sign and abs(dist(p0, pt) + dist(pt, p1) - dist(p0, p1)) < 1e-9 and abs(side(pt)) < 1e-9
s, far = meet((-1, 2), B, C)
print(f"mistake, exit assumed on BC for heading (-1, 2): line BC met at ({far[0]:.3f}, {far[1]:.3f}), s = {s:.3f}")
print(f"mistake, centres 9 apart: y*y = 16 - {4.5 ** 2} = {16 - 4.5 ** 2}, no crossing")
print(f"other crossing (2, {-y1:.6f}); signs of y at C and C': {'+' if y1 > 0 else '-'}, {'+' if -y1 > 0 else '-'}")
print(f"figure, A (200, 200), B (360, 200), C ({200 + 40 * x1:.1f}, {200 - 40 * y1:.1f}), "
      f"D (240, 200), E ({200 + 40 * exits[0][0]:.1f}, {200 - 40 * exits[0][1]:.1f}), C' ({200 + 40 * x1:.1f}, {200 + 40 * y1:.1f})")
assert abs(x2 - x1) < 1e-9 and abs(y2 - y1) < 1e-9 and abs(dist(C, B) - R) < 1e-9
assert hits(12, 1000) == [] and ctl == (4, 1) and s > 1
print("ALL CHECKS PASS")
