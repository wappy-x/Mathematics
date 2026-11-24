# Recurrence and transience of Brownian motion -- the check behind the card.
# Standard library only. Three roads to each hitting chance: the harmonic
# formula, a walk-on-spheres simulation with its own random numbers, and a
# finite-difference solution of the radial Laplace equation. Then Polya's walk.
import math

def phi(d, rho):  # radial harmonic function: log in the plane, rho^(2-d) above
    return math.log(rho) if d == 2 else rho ** (2 - d)

def p_small(d, r, s, R):  # chance of radius r before radius R, from radius s
    if R == math.inf:
        return 1.0 if d == 2 else (r / s) ** (d - 2)
    return (phi(d, R) - phi(d, s)) / (phi(d, R) - phi(d, r))

def norm(x):  # plain loops, not sum(), so Rust can add in the same order
    t = 0.0
    for c in x: t += c * c
    return math.sqrt(t)

def laplacian(f, x, h=1e-3):  # sum of second differences, one per coordinate
    tot = 0.0
    for i in range(len(x)):
        up = list(x); dn = list(x); up[i] += h; dn[i] -= h
        tot += (f(up) - 2 * f(x) + f(dn)) / h ** 2
    return tot

M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

def direction(rng, d):  # uniform point on the unit circle or sphere
    a = 2 * math.pi * rng.uniform()
    if d == 2:
        return [math.cos(a), math.sin(a)]
    z = 2 * rng.uniform() - 1; w = math.sqrt(1 - z * z)
    return [w * math.cos(a), w * math.sin(a), z]

def walk_on_spheres(d, r, s, R, paths, seed, eps=1e-6):
    rng = SplitMix64(seed); hits = 0; steps = 0
    for _ in range(paths):
        x = [s] + [0.0] * (d - 1)
        while True:
            rho = norm(x)
            if rho - r < eps: hits += 1; break
            if R - rho < eps * R: break
            jump = min(rho - r, R - rho); u = direction(rng, d); steps += 1
            x = [c + jump * e for c, e in zip(x, u)]
    p = hits / paths
    return p, math.sqrt(p * (1 - p) / paths), steps / paths

def radial_fd(d, r, s, R, n):  # u'' + (d-1)/rho u' = 0, u(r)=1, u(R)=0, Thomas
    h = (R - r) / n; a, b, c, rhs = [], [], [], []
    for i in range(1, n):
        rho = r + i * h; k = (d - 1) * h / (2 * rho)
        a.append(1 - k); b.append(-2.0); c.append(1 + k); rhs.append(0.0)
    rhs[0] -= a[0] * 1.0
    for i in range(1, n - 1):  # forward sweep
        m = a[i] / b[i - 1]; b[i] -= m * c[i - 1]; rhs[i] -= m * rhs[i - 1]
    u = [0.0] * (n - 1); u[-1] = rhs[-1] / b[-1]
    for i in range(n - 3, -1, -1):
        u[i] = (rhs[i] - c[i] * u[i + 1]) / b[i]
    return u[round((s - r) / h) - 1]

print("harmonic test: numerical Laplacian at a point 1.39 from the centre")
for d, x in ((2, [1.2, 0.7]), (3, [1.2, 0.7, 0.0])):
    rho = norm(x)
    for p in (2 - d, -1 if d == 2 else 1):
        f = (lambda y, p=p: norm(y) ** p) if p != 0 else (lambda y: math.log(norm(y)))
        lab = "log|x|" if p == 0 else f"|x|^{p}"
        num = laplacian(f, x); exact = p * (p + d - 2) * rho ** (p - 2)
        num = num if abs(num) >= 5e-7 else 0.0  # print rounding noise as 0
        print(f"  d={d}  {lab:8s} Laplacian {num:+.6f}  (p(p+d-2)rho^(p-2) = {exact:+.6f})")
        assert abs(num - exact) < 1e-5

pl = p_small(2, 1, 2, 100); sp = p_small(3, 1, 2, math.inf)
print(f"plane, from 2: radius 1 before radius 100 = ln(50)/ln(100) = {pl:.4f}")
print(f"space, from 2: ever hit radius 1 = (1/2)^1 = {sp:.4f}")
print(f"worked: ln 100 = {math.log(100):.4f}, ln 2 = {math.log(2):.4f}, ln 50 = {math.log(50):.4f}")
print(f"worked: ln 500,000 = {math.log(5e5):.3f}, ln 10^6 = {math.log(1e6):.3f}")
assert abs(pl - math.log(50) / math.log(100)) < 1e-12 and abs(sp - 0.5) < 1e-12

print("road 2, walk on spheres (20,000 paths each, seed 20260930)")
for d, R, lab in ((2, 100.0, "100"), (3, 1e6, "10^6")):
    est, se, st = walk_on_spheres(d, 1.0, 2.0, R, 20000, 20260930)
    ex = p_small(d, 1.0, 2.0, R)
    print(f"  d={d} R={lab}: simulated {est:.4f} +- {se:.4f}, formula {ex:.4f}, mean jumps {st:.1f}")
    assert abs(est - ex) < 4 * se
print("road 3, finite differences on the radial equation, step 0.005")
for d in (2, 3):
    fd = radial_fd(d, 1.0, 2.0, 100.0, 19800); ex = p_small(d, 1.0, 2.0, 100.0)
    print(f"  d={d} R=100: grid {fd:.6f}, formula {ex:.6f}")
    assert abs(fd - ex) < 1e-5

print("chance of radius 1 before radius R, from 2   (chart)")
print("  R        d=2      d=3      d=4")
for R in (10, 100, 1000, 10**4, 10**5, 10**6, math.inf):
    lab = "inf" if R == math.inf else f"10^{round(math.log10(R))}"
    print(f"  {lab:6s} " + " ".join(f"{p_small(d, 1, 2, R):8.4f}" for d in (2, 3, 4)))
print("plane, from 2, before radius 100: shrink the target towards a point")
for lab, r in (("0.1", 0.1), ("0.01", 0.01), ("10^-6", 1e-6), ("10^-100", 1e-100)):
    print(f"  r = {lab}: {p_small(2, r, 2, 100):.4f}")
print(f"space, start at 10: ever hit radius 1 = {p_small(3, 1, 10, math.inf):.4f}")

print("what breaks (plane from 2, R = 100, right answer 0.8495)")
lin = (100 - 2) / (100 - 1); inv = p_small(3, 1, 2, 100)
print(f"  radius treated as a 1-D Brownian motion: {lin:.4f}")
print(f"  space's 1/|x| used in the plane: {inv:.4f}")
print(f"  far wall instead of near ball: {1 - pl:.4f}")
print(f"  plane's log used in space, R = 10^6: {p_small(2, 1, 2, 1e6):.4f} (right {p_small(3, 1, 2, 1e6):.4f})")
assert lin > pl > inv

print("Polya: expected visits to the start in 2N steps of the grid walk")
N = 200; a = 1.0; s1 = s2 = 0.0; s3 = 0.0; lf = [0.0]
for k in range(1, N + 1): lf.append(lf[-1] + math.log(k))
for n in range(N + 1):
    if n > 0: a *= (2 * n - 1) / (2 * n)
    t3 = 0.0  # chance the three axes each net to zero, given n steps on them
    for j in range(n + 1):
        for k in range(n - j + 1):
            t3 += math.exp(2 * (lf[n] - lf[j] - lf[k] - lf[n - j - k]) - 2 * n * math.log(3))
    s1 += a; s2 += a * a; s3 += a * t3
    if n in (10, 100, 200):
        print(f"  N={n:3d}: line {s1:7.3f}   plane {s2:6.3f}   space {s3:6.4f}")
u3 = s3 + 2 * (3 / (4 * math.pi)) ** 1.5 * 2 / math.sqrt(N + 0.5)
print(f"  space with tail added: {u3:.4f}; chance of ever returning 1 - 1/u = {1 - 1 / u3:.4f}")
assert abs(1 - 1 / u3 - 0.340537) < 1e-3 and s2 > math.log(N) / math.pi
print("ALL CHECKS PASS")
