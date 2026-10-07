# Integrals round a full turn -- the check behind the card.  Standard library.
# The integral of 1/(A + B cos t + C sin t) over one turn, three roads:
# road 1: z = e^(it) turns it into the loop integral of 1/q(z) round |z| = 1,
#         and 2 pi i times the residue at the pole inside gives the answer;
# road 2: a trapezoid sum straight over t, no complex numbers at all;
# road 3: a trapezoid sum of 1/q(z) dz round the smaller circle |z| = 0.75.
import math

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

def quad(A, B, C):                            # q(z) = iz (A + B cos t + C sin t)
    return (C + 1j * B) / 2, 1j * A, (1j * B - C) / 2

def residue_road(A, B, C):
    p2, p1, p0 = quad(A, B, C)
    root = (p1 * p1 - 4 * p2 * p0) ** 0.5
    poles = sorted([(-p1 + root) / (2 * p2), (-p1 - root) / (2 * p2)], key=abs)
    res = [1 / (2 * p2 * z + p1) for z in poles]  # simple pole: 1 / q'(z)
    return poles, res, 2j * math.pi * res[0]

def trapezoid_t(f, n):                        # road 2: equal steps round one turn
    return sum(f(2 * math.pi * k / n) for k in range(n)) * 2 * math.pi / n

def loop_sum(A, B, C, r, n):                  # road 3: sum of dz / q(z) round |z| = r
    p2, p1, p0 = quad(A, B, C)
    zs = [r * complex(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n)) for k in range(n)]
    return sum(1j * z / (p2 * z * z + p1 * z + p0) for z in zs) * 2 * math.pi / n

wheel = lambda t: 1 / (2 + math.cos(t))
poles, res, road1 = residue_road(2, 1, 0)
h = 1e-6                                      # the residue again, by its limit
limit = h / sum(c * (poles[0] + h) ** k for k, c in zip((2, 1, 0), quad(2, 1, 0)))
exact = 2 * math.pi / math.sqrt(2 * 2 - 1 * 1)
print(f"poles of z^2 + 4z + 1: inside {poles[0].real:.6f}, outside {poles[1].real:.6f}, product {(poles[0] * poles[1]).real:.6f}")
print(f"residue inside, 1/q'(z): {show(res[0])}; by the limit, h = 1e-6: {show(limit)}")
print(f"road 1, 2 pi i x residue: {show(road1)}; 2 pi / sqrt 3 = {exact:.6f}")
errs = []
for n in (4, 8, 16):
    errs.append(abs(trapezoid_t(wheel, n) - exact))
    print(f"road 2, trapezoid in t, N = {n}: {trapezoid_t(wheel, n):.6f}, error {errs[-1]:.12f}")
road2, road3 = trapezoid_t(wheel, 64), loop_sum(2, 1, 0, 0.75, 128)
print(f"road 2, N = 64: {road2:.6f}; road 3, loop |z| = 0.75, N = 128: {show(road3)}")
print(f"average over one turn: {road1.real / (2 * math.pi):.6f}; harmonic-mean height {2 * math.pi / road1.real:.6f} radii = {40 * math.pi / road1.real:.6f} m")
poles2, res2, case2 = residue_road(5, 0, 4)
trap2, loop2 = trapezoid_t(lambda t: 1 / (5 + 4 * math.sin(t)), 64), loop_sum(5, 0, 4, 0.75, 128)
print(f"second case 1/(5 + 4 sin t): inside pole {show(poles2[0])}, outside {show(poles2[1])}")
print(f"second case: residue road {show(case2)}, trapezoid {trap2:.6f}, loop {show(loop2)}, 2 pi/3 = {2 * math.pi / 3:.6f}")
print(f"mistake, one over the average height: {1 / 2:.6f}, integral {2 * math.pi / 2:.6f}")
print(f"mistake, both poles counted: {show(2j * math.pi * (res[0] + res[1]))}; outside pole only: {show(2j * math.pi * res[1])}")
print(f"mistake, dt read as dz: {show(2j * math.pi * 2 * poles[0] / (poles[0] - poles[1]))}")
blow = [trapezoid_t(lambda t: 1 / (1 + math.cos(t + math.pi / n)), n) for n in (8, 64, 512)]
print("hypothesis dropped, 1/(1 + cos t), midpoint sums N = 8, 64, 512: " + ", ".join(f"{b:.6f}" for b in blow))
print(f"figure, 50 per unit, origin (230, 120), inside pole ({230 + 50 * poles[0].real:.2f}, 120), outside pole ({230 + 50 * poles[1].real:.2f}, 120), radii 50 and 37.5")
assert abs(road1 - road2) < 1e-12                          # residue against the plain t sum
assert abs(road3 - exact) < 1e-12 and abs(limit - res[0]) < 1e-5  # a different loop, same answer
assert errs[0] > errs[1] > errs[2] and errs[2] < 1e-7 and blow[0] < blow[1] < blow[2]
assert abs(case2 - trap2) < 1e-12 and abs(loop2 - 2 * math.pi / 3) < 1e-12
print("ALL CHECKS PASS")
