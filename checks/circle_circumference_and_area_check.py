# Circles, on a bicycle wheel 70 cm across.  Nothing is imported, so pi is not
# borrowed.  Road one finds pi from polygons inside and outside the rim.  Road
# two measures the rim and the disc on a grid, with Pythagoras alone.  Lengths
# are in cm, areas in square cm.
D = 70.0
R = D / 2

def pi_bounds(doublings):                  # radius 1; perimeter over the width, 2
    n, s = 6, 1.0                          # hexagon inside: each side equals the radius
    for _ in range(doublings):             # double the sides, by Pythagoras
        n, s = 2 * n, s / (2 + (4 - s * s) ** 0.5) ** 0.5
    t = s / (1 - s * s / 4) ** 0.5         # side of the matching polygon outside
    return n, n * s / 2, n * t / 2

def walk(r, hops):                         # an eighth of the rim in straight hops, x 8
    end, total, x0, y0 = r / 2 ** 0.5, 0.0, 0.0, r
    for k in range(1, hops + 1):
        x = end * k / hops
        y = (r * r - x * x) ** 0.5         # the rim point above x, by Pythagoras
        total += ((x - x0) ** 2 + (y - y0) ** 2) ** 0.5
        x0, y0 = x, y
    return 8 * total

def squares(r, per_cm):                    # grid squares wholly inside, and touching, x 4
    m, inside, touch = round(r * per_cm), 0, 0
    for i in range(m):
        for j in range(m):
            inside += (i + 1) ** 2 + (j + 1) ** 2 <= m * m
            touch += i * i + j * j < m * m
    return 4 * inside / per_cm ** 2, 4 * touch / per_cm ** 2

(n6, lo6, hi6), (n96, lo96, hi96), (nf, PI, hi) = pi_bounds(0), pi_bounds(4), pi_bounds(20)
C, A, rim = PI * D, PI * R * R, walk(R, 10000)
(c_lo, c_hi), (m_lo, m_hi) = squares(R, 1), squares(R, 10)
print(f"wheel: diameter {D:.0f} cm, radius {R:.0f} cm")
print(f"pi from {n6} sides: between {lo6:.6f} and {hi6:.6f}")
print(f"pi from {n96} sides: between {lo96:.6f} and {hi96:.6f}; Archimedes wrote "
      f"{3 + 10 / 71:.6f} and {3 + 1 / 7:.6f}")
print("gap, outside minus inside, 6 to 96 sides: "
      + ", ".join(f"{pi_bounds(k)[2] - pi_bounds(k)[1]:.6f}" for k in range(5)))
print(f"pi from {nf} sides: between {PI:.10f} and {hi:.10f}")
print(f"distance per turn, pi x {D:.0f}: {C:.6f} cm; turns per km: {100000 / C:.2f}")
print(f"distance per turn, 10000 hops round an eighth of the rim, x 8: {rim:.6f} cm")
print(f"disc, pi x {R:.0f} x {R:.0f}: {A:.6f}; unrolled, half of {C:.6f} x {R:.0f}: {C * R / 2:.6f}")
print(f"disc, centimetre squares: between {c_lo:.0f} and {c_hi:.0f}")
print(f"disc, millimetre squares: between {m_lo:.2f} and {m_hi:.2f}")
print(f"disc / radius^2 from the squares: between {m_lo / R / R:.6f} and {m_hi / R / R:.6f}")
print(f"second case, wheel {2 * D:.0f} cm: {PI * 2 * D:.6f} cm per turn, disc {PI * D * D:.6f}")
print(f"measuring wheel, 100 cm per turn: diameter {100 / PI:.6f} cm")
print(f"mistake, radius in pi x d: {PI * R:.6f} cm per turn")
print(f"mistake, pi as 3: {3 * D:.6f} cm per turn; a real km reads {3 * D / C:.6f} km")
print(f"mistake, diameter in pi r^2: {PI * D * D:.6f}; whole rim x radius: {C * R:.6f}")
print(f"figure 1, 1 cm = 1.1: centres (50, 71.5) and ({50 + 1.1 * C:.2f}, 71.5), radius {1.1 * R:.1f}")
print(f"figure 2, 1 cm = 1.4: disc radius {1.4 * R:.0f}, rings {R / 5:.0f} cm wide; base ends at ({44 + 1.4 * C:.2f}, 215); strips end at x "
      + ", ".join(f"{44 + 1.4 * 2 * PI * p:.2f}" for p in (28, 21, 14, 7)))
assert 3 + 10 / 71 < lo96 < PI < hi < hi96 < 3 + 1 / 7   # Archimedes' two fractions
assert abs(rim - C) < 1e-6                                 # rim: grid walk against pi x 70
assert c_lo < m_lo < A < m_hi < c_hi                      # disc: mm squares inside cm, around pi r^2
assert m_lo < rim * R / 2 < m_hi                           # half rim x radius, no pi at all
print("ALL CHECKS PASS")
