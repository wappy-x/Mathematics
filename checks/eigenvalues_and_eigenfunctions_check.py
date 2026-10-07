# Eigenvalue problems -- the check behind the card.  Standard library only.  A 1 m string,
# pinned at both ends, waves at 220 m/s: -y'' = lam y, y(0) = y(1) = 0.  Road one: the closed
# form n^2 pi^2.  Road two: RK4 shots bisected on lam.  Road three: finite differences.
import math
C, PI = 220.0, math.pi
def shoot(lam, n=1000):                # y'' = -lam y, y(0) = 0, slope 0.1: (y(1) in cm, y'(1), nodes)
    f, h, y, p, nodes = (lambda y, p: (p, -lam * y)), 1.0 / n, 0.0, 0.1, 0
    for i in range(n):
        a = f(y, p); b = f(y + h / 2 * a[0], p + h / 2 * a[1])
        c = f(y + h / 2 * b[0], p + h / 2 * b[1]); d = f(y + h * c[0], p + h * c[1])
        yn = y + h / 6 * (a[0] + 2 * b[0] + 2 * c[0] + d[0]); p += h / 6 * (a[1] + 2 * b[1] + 2 * c[1] + d[1])
        nodes += i < n - 1 and yn * y < 0; y = yn
    return 100 * y, p, nodes
def roots(g, count, step=0.5):         # scan lam upward from 0.5, bisect each sign change of g
    out, a, ga = [], step, g(step)
    while len(out) < count:
        b = a + step; gb = g(b)
        if ga * gb < 0:
            lo, hi, glo = a, b, ga
            for _ in range(50):
                m = (lo + hi) / 2; gm = g(m)
                if glo * gm <= 0: hi = m
                else: lo, glo = m, gm
            out.append((lo + hi) / 2)
        a, ga = b, gb
    return out
def fd(N, k):                          # k-th eigenvalue of (1/h^2) tridiag(-1, 2, -1), N - 1 rows, by Sturm counts
    q = N * N                          # 1/h^2
    def below(x):                      # eigenvalues below x = negative pivots of A - x I
        d, cnt = 2 * q - x, 0
        for i in range(N - 1):
            if i: d = 2 * q - x - q * q / (d or 1e-300)
            cnt += d < 0
        return cnt
    lo, hi = 0.0, 4.0 * q
    for _ in range(60): m = (lo + hi) / 2; lo, hi = (lo, m) if below(m) >= k else (m, hi)
    return (lo + hi) / 2
lam, exact = roots(lambda l: shoot(l)[0], 3), [(n * PI) ** 2 for n in (1, 2, 3)]
free, errs = roots(lambda l: shoot(l)[1], 3), []  # far end free to slide: y'(1) = 0
hz = lambda l: C * math.sqrt(l) / (2 * PI)
print(f"not eigenvalues: lambda = -1, 0, 10 lands y(1) at {shoot(-1)[0]:.2f}, {shoot(0)[0]:.2f}, {shoot(10)[0]:.2f} cm; sin(sqrt 10) = sin({math.sqrt(10):.4f}) = {math.sin(math.sqrt(10)):.4f}")
print("chart lambda", " ".join(str(5 * i) for i in range(21)))
print("chart y(1) cm", " ".join(f"{shoot(5 * i)[0]:.2f}" for i in range(21)))
print("shooting roots, both ends pinned:", " ".join(f"{l:.6f}" for l in lam))
print("closed form n^2 pi^2:            ", " ".join(f"{l:.6f}" for l in exact))
print("frequencies c sqrt(lam)/(2 pi):", " ".join(f"{hz(l):.2f}" for l in lam), f"Hz; ratios 1 : {hz(lam[1]) / hz(lam[0]):.3f} : {hz(lam[2]) / hz(lam[0]):.3f}")
print("nodes inside the string for n = 1, 2, 3:", " ".join(str(shoot(l)[2]) for l in lam))
for N in (10, 20, 40):
    e = [fd(N, k) for k in (1, 2, 3)]; errs.append(exact[0] - e[0])
    print(f"finite differences, {N - 1} inner points: {e[0]:.4f} {e[1]:.4f} {e[2]:.4f}; error in lambda_1 {errs[-1]:.5f}")
print(f"error ratios as the grid halves: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print("free far end: lambda", " ".join(f"{l:.4f}" for l in free), "->", " ".join(f"{hz(l):.2f}" for l in free), "Hz")
print("mistake, frequency in proportion to lambda:", " ".join(f"{110 * l / lam[0]:.2f}" for l in lam), "Hz")
print(f"mistake, one pin only: lambda = 50 gives a shape at {hz(50):.2f} Hz, y(1) = {shoot(50)[0]:.2f} cm")
print(f"figure, x_px = 30 + 220 x; rows at y_px 45 110 175, 25 px per unit; nodes x = {1 / 2:.3f}, {1 / 3:.3f}, {2 / 3:.3f} m at x_px {30 + 220 / 2:.1f}, {30 + 220 / 3:.1f}, {30 + 440 / 3:.1f}")
assert all(abs(a - b) < 1e-6 for a, b in zip(lam, exact))
assert all(abs(a - ((n - 0.5) * PI) ** 2) < 1e-6 for n, a in zip((1, 2, 3), free))
assert [shoot(l)[2] for l in lam] == [0, 1, 2]
assert all(3.9 < r < 4.1 for r in (errs[0] / errs[1], errs[1] / errs[2]))    # error falls 4x per halving: order two
print("ALL CHECKS PASS")
