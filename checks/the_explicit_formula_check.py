# The explicit formula -- the check behind the card.  Standard library only.
# Zeta by Euler-Maclaurin; 1,000 zeros from sign changes of Z(t), checked, then
# fed into von Mangoldt's formula at x = 7.5 and nearby.
import math, cmath
B = [1/6, -1/30, 1/42, -1/30, 5/66, -691/2730, 7/6, -3617/510, 43867/798, -174611/330]

def zeta(s):                                  # Euler-Maclaurin, valid for any s != 1
    n_cut = int(abs(s.imag) / 2) + 10
    tot = sum(cmath.exp(-s * math.log(n)) for n in range(1, n_cut))
    big = cmath.exp(-s * math.log(n_cut))
    tot += n_cut * big / (s - 1) + big / 2
    term = s * big / n_cut
    for k in range(1, 11):
        tot += B[k - 1] / math.factorial(2 * k) * term
        term *= (s + 2 * k - 1) * (s + 2 * k) / (n_cut * n_cut)
    return tot

def theta(t):                                 # Riemann-Siegel angle, Stirling series
    return (t / 2 * math.log(t / (2 * math.pi)) - t / 2 - math.pi / 8
            + 1 / (48 * t) + 7 / (5760 * t ** 3) + 31 / (80640 * t ** 5))

def z_real(t):                                # Z(t): zeta on the line, turned real
    return (cmath.exp(1j * theta(t)) * zeta(complex(0.5, t))).real

def find_zeros(count, step=0.05):             # scan for sign changes, then Illinois
    out, t, zp = [], 10.0, z_real(10.0)
    while len(out) < count:
        a, t = t, t + step
        zc = z_real(t)
        if zp * zc < 0:
            lo, hi, flo, fhi = a, t, zp, zc
            for _ in range(80):
                m = hi - fhi * (hi - lo) / (fhi - flo)
                fm = z_real(m)
                lo, flo = (hi, fhi) if fm * fhi < 0 else (lo, flo / 2)
                hi, fhi = m, fm
                if abs(hi - lo) < 1e-12:
                    break
            out.append(hi)
        zp = zc
    return out

def sieve(n):                                 # Eratosthenes: every prime up to n
    ok = bytearray([0, 0]) + bytearray([1]) * (n - 1)
    for i in (i for i in range(2, int(n ** 0.5) + 1) if ok[i]):
        ok[i * i::i] = bytearray(len(ok[i * i::i]))
    return [i for i in range(n + 1) if ok[i]]

def psi(x, primes):                           # the staircase: log p at every p^k <= x
    tot = 0.0
    for p in (p for p in primes if p <= x):
        pk = p
        while pk <= x:
            tot, pk = tot + math.log(p), pk * p
    return tot

def wave(x, t):                               # one mirror pair: 2 Re(x^rho / rho)
    lx = math.log(x)
    return 2 * math.sqrt(x) * (0.5 * math.cos(t * lx) + t * math.sin(t * lx)) / (0.25 + t * t)

def formula(x, zs, k, pairs=2.0, log2pi=True):
    smooth = x - (math.log(2 * math.pi) if log2pi else 0.0) - 0.5 * math.log(1 - x ** -2)
    return smooth - pairs / 2 * sum(wave(x, t) for t in zs[:k])

def logderiv_max(height):                     # max |zeta'/zeta| on -1 <= sigma <= 2
    best = 0.0
    for j in range(61):
        s = complex(-1 + 0.05 * j, height)
        d = (zeta(s + 1e-5) - zeta(s - 1e-5)) / 2e-5
        best = max(best, abs(d / zeta(s)))
    return best

zs, primes = find_zeros(1000), sieve(10 ** 6)
lmfdb = {1: 14.1347251417, 10: 49.7738324777, 100: 236.5242296658, 1000: 1419.4224809460}
gap = min(range(999), key=lambda i: zs[i + 1] - zs[i])
smooth_count = theta(1420.0) / math.pi + 1
window = max(sum(1 for g in zs if a <= g < a + 1) for a in range(10, 1420))
print(f"zeros found: {len(zs)}, heights {zs[0]:.6f} to {zs[-1]:.6f}")
print(f"smallest gap {zs[gap + 1] - zs[gap]:.6f}, between zeros {gap + 1} and {gap + 2}")
print("LMFDB table, zeros 1, 10, 100, 1000:", [f"{zs[n - 1]:.6f}" for n in lmfdb])
print(f"zeros below 1420: {sum(1 for g in zs if g < 1420)}; smooth count RS angle/pi + 1 = {smooth_count:.3f}")
print(f"most zeros in one window [a, a+1) up to 1420: {window}; log 1420 = {math.log(1420):.3f}")
edges = []
for a in (100, 500, 1000):
    cuts = [0.0] + [g - a for g in zs if a < g < a + 1] + [1.0]
    i = max(range(len(cuts) - 1), key=lambda i: cuts[i + 1] - cuts[i])
    T = a + (cuts[i] + cuts[i + 1]) / 2
    near = min(abs(T - g) for g in zs)
    edges.append((logderiv_max(T), math.log(T) ** 2))
    print(f"T = {T:.3f}: nearest zero {near:.3f} away, max |zeta'/zeta| {edges[-1][0]:.2f}, log^2 T {edges[-1][1]:.2f}")
bad = logderiv_max(zs[0] + 0.001)
print(f"T = first zero + 0.001: max |zeta'/zeta| {bad:.1f}")
x, exact = 7.5, psi(7.5, primes)
errs = [formula(x, zs, k) - exact for k in (0, 10, 100, 1000)]
print(f"psi(7.5) = {exact:.6f} = log 420 = {math.log(420):.6f}")
for k, e in zip((0, 10, 100, 1000), errs):
    print(f"{k:>4} zeros at 7.5: {exact + e:.6f}, miss {e:+.6f}")
mid = psi(7, primes) - math.log(7) / 2
print(f"at the jump x = 7, midpoint {mid:.6f}; 10, 100, 1000 zeros:",
      " ".join(f"{formula(7.0, zs, k):.6f}" for k in (10, 100, 1000)))
si = sum((1 if j in (0, 1000) else 4 if j % 2 else 2) * (math.sin(u) / u if u else 1.0)
         for j in range(1001) for u in [j * math.pi / 1000]) * math.pi / 3000
gibbs = (si / math.pi - 0.5) * math.log(7)
rings = []
for k in (10, 100, 1000):
    top, at = max((formula(7 + i * 0.0005, zs, k), 7 + i * 0.0005) for i in range(1, 1001))
    rings.append((top - exact, at - 7, 7 * math.pi / zs[k - 1]))
    print(f"{k:>4} zeros, T = {zs[k - 1]:.3f}: peak {top:.4f} at x = {at:.4f}, "
          f"overshoot {top - exact:.4f}, Gibbs spot 7 + {7 * math.pi / zs[k - 1]:.4f}")
print(f"Gibbs overshoot (Si(pi)/pi - 1/2) x log 7 = {gibbs:.4f}")
big = psi(10 ** 6, primes)
print(f"primes below a million {len(primes)}; psi(10^6) = {big:.3f}; formula minus psi at 10^6 + 0.5:",
      " ".join(f"{formula(10 ** 6 + 0.5, zs, k) - big:.2f}" for k in (0, 10, 100, 1000)))
euler = sum(1 / n for n in range(1, 10001)) - math.log(10000) - 1 / 20000 + 1 / (12 * 10 ** 8)
target = 2 + euler - math.log(4 * math.pi)
sq = [sum(2 / (0.25 + t * t) for t in zs[:k]) for k in (10, 100, 1000)]
tail = (math.log(zs[-1] / (2 * math.pi)) + 1) / (math.pi * zs[-1])
print("sum 2/|rho|^2 over 10, 100, 1000 pairs:", " ".join(f"{v:.6f}" for v in sq),
      f"+ tail {tail:.6f} = {sq[-1] + tail:.6f}; 2 + gamma - log 4pi = {target:.6f}")
ab = [sum(2 / math.sqrt(0.25 + t * t) for t in zs[:k]) for k in (10, 100, 1000)]
print("sum 2/|rho| over 10, 100, 1000 pairs:", " ".join(f"{v:.3f}" for v in ab),
      f"; log^2(T/2pi)/2pi at T = {zs[-1]:.0f}: {math.log(zs[-1] / (2 * math.pi)) ** 2 / (2 * math.pi):.3f}")
print(f"break: no -log 2pi, 1000 zeros at 7.5: miss {formula(x, zs, 1000, log2pi=False) - exact:+.4f}")
print(f"break: one zero of each pair, 1000 zeros at 7.5: miss {formula(x, zs, 1000, pairs=1.0) - exact:+.4f}")
print(f"break: primes only, theta(7.5) = log 210 = {math.log(210):.4f}: miss {formula(x, zs, 1000) - math.log(210):+.4f}")
print(f"constants: log 2pi {math.log(2 * math.pi):.6f}, trivial term {-0.5 * math.log(1 - x ** -2):.6f}, "
      f"Si(pi) {si:.6f}, gamma {euler:.6f}, Gibbs fraction {si / math.pi - 0.5:.4f}, log 2 {math.log(2):.4f}, "
      f"x log^2(xT)/T at 10^6 {1e6 * math.log(1e6 * zs[-1]) ** 2 / zs[-1]:.0f}")
grid = [6.5 + 0.05 * i for i in range(41)]
for name, f in [("staircase", lambda v: psi(v, primes)), ("10 zeros", lambda v: formula(v, zs, 10)),
                ("100 zeros", lambda v: formula(v, zs, 100))]:
    print(f"chart {name}:", ", ".join(f"{f(v):.2f}" for v in grid))
assert all(abs(zs[n - 1] - v) < 1e-8 for n, v in lmfdb.items())          # a named table
assert sum(1 for g in zs if g < 1420) == 1000 and abs(1000 - smooth_count) < 1
assert abs(exact - math.log(420)) < 1e-12 and abs(errs[3]) < abs(errs[2]) < abs(errs[1]) < abs(errs[0])
assert all(m < l2 for m, l2 in edges) and bad > 100
assert abs(rings[2][0] - gibbs) < 0.01 and abs(rings[2][1] / rings[2][2] - 1) < 0.1
assert len(primes) == 78498 and abs(sq[-1] + tail - target) < 1e-4
assert all(abs(wave(x, t) - 2 * (cmath.exp(complex(0.5, t) * math.log(x)) / complex(0.5, t)).real) < 1e-12 for t in zs)
print("ALL CHECKS PASS")
