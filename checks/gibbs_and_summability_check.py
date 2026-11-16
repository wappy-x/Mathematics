# The Gibbs overshoot and the cure -- the check behind the card.  Only sin, cos
# and pi are imported.  Square wave: +1 V on (0, pi), -1 V on (-pi, 0), x = 2 pi 220 t.
# S(M, x) keeps harmonics up to M; sigma(N, x) averages S_0 .. S_(N-1) (Fejer).
from math import sin, cos, pi

def S(M, x):                                # the partial sum of degree M
    s = 0.0
    for n in range(1, M + 1, 2):
        s += 4 / pi * sin(n * x) / n
    return s

def sigma(N, x):                            # road one: taper harmonic n by 1 - n/N
    s = 0.0
    for n in range(1, N, 2):
        s += (1 - n / N) * 4 / pi * sin(n * x) / n
    return s

def sigma_avg(N, x):                        # road two: add S_0 .. S_(N-1), divide by N
    total, s = 0.0, 0.0
    for k in range(N):
        if k % 2:
            s += 4 / pi * sin(k * x) / k
        total += s
    return total / N

def fejer(N, t):                            # F_N(t) = (sin(Nt/2) / sin(t/2))^2 / N
    d = sin(t / 2)
    return float(N) if abs(d) < 1e-12 else (sin(N * t / 2) / d) ** 2 / N

def dirichlet(M, t):                        # D_M(t) = sin((M + 1/2) t) / sin(t/2)
    d = sin(t / 2)
    return 2.0 * M + 1 if abs(d) < 1e-12 else sin((M + 0.5) * t) / d

def simpson(g, a, b, n):                    # our own integrator, n even
    h, s = (b - a) / n, 0.0
    for i in range(n + 1):
        s += g(a + i * h) * (1 if i in (0, n) else 4 if i % 2 else 2)
    return s * h / 3

def sigma_kernel(N, x):                     # road three: 1 - (1/pi) * kernel area on the -1 side
    return 1 - simpson(lambda t: fejer(N, t), x, x + pi, 20000) / pi

def solve(g, lo, hi, target):               # bisection for g(x) = target, g rising
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if g(mid) < target else (lo, mid)
    return (lo + hi) / 2

def Si(u):                                  # sine integral, power series
    s, term, k = 0.0, u, 0
    while abs(term) > 1e-17:
        s += term / (2 * k + 1)
        k += 1
        term *= -u * u / ((2 * k) * (2 * k + 1))
    return s

us = lambda x: x / (2 * pi * 220) * 1e6      # radians to microseconds after the switch
yn = lambda c: "yes" if c else "no"
f6 = lambda v: f"{0.0 if abs(v) < 5e-7 else v:.6f}"   # never "-0.000000"
print(f"siren: +-1 V, 220 cycles a second, 440 switches; 1 radian = {us(1):.2f} us; CD rate 44100: "
      f"harmonics up to n = {22050 // 220}, last odd n = {(22050 // 220 - 1) | 1} ({((22050 // 220 - 1) | 1) * 220} Hz)")
print(f"by hand: 4/pi = {f6(4 / pi)}, sin(pi/4) = {f6(sin(pi / 4))}, S_1(pi/4) = S_2(pi/4) = {f6(S(2, pi / 4))} V")
print(f"by hand: S_3(pi/4) = {f6(S(3, pi / 4))} V, sigma_4(pi/4) = {f6(sigma(4, pi / 4))} V, "
      f"average of S_0..S_3 = {f6(sigma_avg(4, pi / 4))} V")
print(f"by hand: S_3(pi/2) = {f6(S(3, pi / 2))} V, sigma_4(pi/2) = {f6(sigma(4, pi / 2))} V")
grid = [j * pi / 20000 for j in range(1, 20001)]
fmin, dmin = min(fejer(100, t) for t in grid), min(dirichlet(99, t) for t in grid)
area = simpson(lambda t: fejer(100, t), -pi, pi, 20000) / (2 * pi)
print(f"kernels: F_100 lowest {f6(fmin)}, mean {f6(area)}; D_99 at 0 {dirichlet(99, 0):.0f}, lowest {dmin:.2f}")
gaps = []
for N in (20, 100, 500):
    peak, at = S(N - 1, pi / N), sigma(N, pi / N)
    g = [sigma(N, j * pi / 2000) for j in range(1, 2000)]
    rises = all(g[i + 1] >= g[i] for i in range(999))
    roads = [sigma(N, pi / 2), sigma_avg(N, pi / 2), sigma_kernel(N, pi / 2)]
    err, bound = 1 - roads[0], 2 / N
    worst = max(1 - sigma(N, 0.1 + j * (pi - 0.2) / 400) for j in range(401))
    xs, xp = solve(lambda x: sigma(N, x), 0, pi / 2, 0.9), solve(lambda x: S(N - 1, x), 0, pi / N, 0.9)
    gaps.append((N, peak - 1, at, max(g), rises, roads, err, worst, N * xs, N * xp))
    print(f"N = {N}: S_{N - 1} peak {f6(peak)} V at x = pi/N ({us(pi / N):.2f} us); sigma_{N} there {f6(at)} V")
    print(f"N = {N}: sigma_{N} highest {f6(max(g))} V, at x = pi/2: {yn(g.index(max(g)) == 999)}; "
          f"rises without a dip: {yn(rises)}")
    print(f"N = {N}: three roads at pi/2: {' '.join(f6(r) for r in roads)}")
    print(f"N = {N}: mid-top error {f6(err)} V, N x error {f6(N * err)}, bound 2/N {f6(bound)}, "
          f"bound/true {bound / err:.2f}; worst on [0.1, pi-0.1] {f6(worst)} V")
    print(f"N = {N}: reaches 0.9 V at {us(xs):.2f} us (N x = {N * xs:.4f}); S_{N - 1} at {us(xp):.2f} us (N x = {N * xp:.4f})")
H = lambda u: simpson(lambda s: 1.0 if s == 0 else (sin(s / 2) / (s / 2)) ** 2, 0, u, 4000) / pi
uH, uS = solve(H, pi, 4 * pi, 0.9), solve(lambda u: 2 / pi * Si(u), 0, pi, 0.9)
print(f"limits: (2/pi) Si(pi) = {f6(2 / pi * Si(pi))} ({(2 / pi * Si(pi) - 1) / 2 * 100:.2f}% of the jump), H(pi) = {f6(H(pi))}, 2/pi = {f6(2 / pi)}, "
      f"0.9 V at N x = {uH:.4f} (sigma), {uS:.4f} (S)")
step = 2 * pi * 220 * 1e-5                  # chart: every 10 microseconds, 0 to 200
print("chart, S_99:", " ".join(f"{S(99, k * step):.2f}" for k in range(21)))
print("chart, sigma_100:", " ".join(f"{sigma(100, k * step):.2f}" for k in range(21)))
top_b = [2 / pi * simpson(lambda x: sin(n * x), 0, pi, 2000) for n in range(1, 6)]
top_a = [2 / pi * simpson(lambda x: cos(n * x), 0, pi, 2000) for n in range(5)]
print("half-range, +1 V on (0, pi): sine b_1..b_5", " ".join(f6(v) for v in top_b))
print("half-range, +1 V on (0, pi): cosine a_0..a_4", " ".join(f6(v) for v in top_a))

def ramp_sine(M, x):                        # odd extension of x/pi: the sawtooth, jump 2 V at pi
    s = 0.0
    for n in range(1, M + 1):
        s += 2 / pi * (1 if n % 2 else -1) * sin(n * x) / n
    return s

def ramp_cosine(M, x):                      # even extension of x/pi: the triangle, no jump
    s = 0.5
    for n in range(1, M + 1, 2):
        s -= 4 / (pi * pi) * cos(n * x) / (n * n)
    return s

odd_sq = 0.0
for n in range(1, 100, 2):
    odd_sq += 1 / (n * n)
tail = 4 / (pi * pi) * (pi * pi / 8 - odd_sq)
rb1 = 2 / pi * simpson(lambda x: x / pi * sin(x), 0, pi, 2000)
ra1 = 2 / pi * simpson(lambda x: x / pi * cos(x), 0, pi, 2000)
rover = max(ramp_sine(99, x) - x / pi for x in (pi - j * 0.2 / 4000 for j in range(1, 4001)))
rworst = max(abs(ramp_cosine(99, j * pi / 2000) - j / 2000) for j in range(2001))
print(f"ramp x/pi V: b_1 {f6(rb1)} (formula {f6(2 / pi)}), a_1 {f6(ra1)} (formula {f6(-4 / pi ** 2)})")
print(f"ramp, degree 99: sine series overshoots the ramp by {f6(rover)} V; cosine series worst error {f6(rworst)} V, tail {f6(tail)}")
N, s100 = 100, gaps[1][3]
print(f"mistake 1, last partial sum: overshoot {', '.join(f6(g[1]) for g in gaps)} V for N = 20, 100, 500")
print(f"mistake 2, divide by N - 1 = 99: peak {f6(s100 * N / (N - 1))} V")
tone = 0.0
for k in range(N):                          # S_0 of sin x is 0; S_1 onwards is sin x itself
    tone += 0.0 if k == 0 else sin(pi / 2)
print(f"mistake 3, pure tone sin x at pi/2: sigma_100 {f6(tone / N)} V, S_1 {f6(sin(pi / 2))} V")
print(f"mistake 4, sine series of the top half: peak {f6(gaps[1][1] + 1)} V; cosine series {f6(top_a[0] / 2)} V")
for (N, over, at, top, rises, roads, err, worst, nxs, nxp) in gaps:
    assert abs(roads[0] - roads[1]) < 1e-12 and abs(roads[0] - roads[2]) < 1e-9   # three roads
    assert top < 1 and rises and over > 0.178                  # no ear for sigma; ear for S
    assert err <= 2 / N                                        # the tail bound holds
assert abs(sigma(4, pi / 4) - sigma_avg(4, pi / 4)) < 1e-12 and fmin >= 0 > dmin and abs(area - 1) < 1e-9
assert abs(gaps[2][1] + 1 - 2 / pi * Si(pi)) < 1e-4            # Gibbs limit, two roads
assert abs(gaps[2][2] - H(pi)) < 1e-4 and abs(gaps[2][6] * 500 - 2 / pi) < 1e-3
assert abs(gaps[2][8] - uH) < 0.01 and abs(gaps[2][9] - uS) < 0.01
assert all(abs(top_b[n - 1] - (4 / (pi * n) if n % 2 else 0)) < 1e-9 for n in range(1, 6))
assert abs(top_a[0] - 2) < 1e-9 and all(abs(v) < 1e-9 for v in top_a[1:])
assert abs(rworst - tail) < 1e-9 and abs(rover - gaps[1][1]) < 1e-3 and abs(ra1 + 4 / pi ** 2) < 1e-9
print("ALL CHECKS PASS")
