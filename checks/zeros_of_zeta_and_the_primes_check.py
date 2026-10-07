# Zeta's zeros and the primes -- the check behind the card.  Standard library only.  Primes by a
# sieve and by Legendre; li by series and by integral; the first zero by a chase and by a box.
import math, functools
X = 10**6
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0
for p in range(2, 1001):
    if flag[p]: flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(X + 1) if flag[p]]
@functools.lru_cache(None)
def phi(x, a):                       # numbers up to x with none of the first a primes as a factor
    return x if a == 0 or x == 0 else phi(x, a - 1) - phi(x // primes[a - 1], a - 1)
powers = [(p, p ** k) for p in primes for k in range(1, 20) if p ** k <= X]   # (p, p^k)
psi = lambda x: sum(math.log(p) for p, q in powers if q <= x)                 # ln p per power
lam = sum(math.log(p) / q ** 2 for p, q in powers)                            # -zeta'/zeta(2), cut at 10^6
gam = sum(1 / k for k in range(1, 1001)) - math.log(1000) - 1 / 2000 + 1 / 12e6  # Euler's constant
li_series = lambda y: gam + math.log(y) + sum(y ** k / (k * math.factorial(k)) for k in range(1, 150))
mid = lambda f, a, b, n=40000: (b - a) / n * sum(f(a + (k + 0.5) * (b - a) / n) for k in range(n))
li_integral = lambda y: mid(lambda u: 2 * math.sinh(u) / u, 0, y) - mid(lambda u: math.exp(-u) / u, y, y + 60)
def zeta(s, N=50):                   # head sum + tail integral + end corrections (Euler-Maclaurin)
    r = lambda m: math.prod(s + j for j in range(m)) * N ** (-s - m)
    return (sum(n ** -s for n in range(1, N)) + N ** (1 - s) / (s - 1) + N ** -s / 2
            + r(1) / 12 - r(3) / 720 + r(5) / 30240)
def secant(a, b):                    # chase a zero of zeta through the complex plane
    for _ in range(60):
        if abs(zeta(b)) > 1e-12: a, b = b, b - zeta(b) * (b - a) / (zeta(b) - zeta(a))
    return b
M, c = 2000, [10j, 1 + 10j, 1 + 20j, 20j, 10j]         # the box 0 < Re s < 1, 10 < Im s < 20
box = [a + (b - a) * k / M for a, b in zip(c, c[1:]) for k in range(M)] + [10j]
q = [zeta(w) / zeta(v) for v, w in zip(box, box[1:])]  # step-by-step ratios of zeta round the box
dlog = [complex(math.log(abs(u)), math.atan2(u.imag, u.real)) for u in q]
count, where = sum(dlog) / (2j * math.pi), sum((a + b) / 2 * d for a, b, d in zip(box, box[1:], dlog)) / (2j * math.pi)
z1, slope = secant(0.6 + 14j, 0.6 + 14.3j), -(zeta(2.00001) - zeta(1.99999)) / 2e-5 / zeta(2)
ts, zeros = [k / 10 for k in range(1, 1001)], []; mod = [abs(zeta(0.5 + 1j * t)) for t in ts]
for k in range(1, 999):              # every dip of |zeta| on the line, chased to a zero
    z = secant(0.5 + 1j * ts[k], 0.5 + 1j * ts[k] + 0.05j) if mod[k] <= min(mod[k - 1], mod[k + 1]) else None
    if z and z.imag > 1 and all(abs(z - w) > 1e-6 for w in zeros): zeros.append(z)
rebuild = lambda x, K: x - math.log(2 * math.pi) - math.log(1 - x ** -2) / 2 - 2 * sum((x ** r / r).real for r in zeros[:K])
xs, row = [k + 0.5 for k in range(1, 30)], lambda v: ", ".join(f"{u:.2f}" for u in v)
for x, a in ((100, 4), (1000, 11), (10**6, 168)):   # a = number of primes up to sqrt(x)
    pi, y = sum(1 for p in primes if p <= x), math.log(x)
    print(f"x = {x}: pi sieve {pi}, Legendre {phi(x, a) + a - 1}; x/ln x {x / y:.2f}; "
          f"li series {li_series(y):.2f}, integral {li_integral(y):.2f}; pi - li {pi - li_series(y):.2f}")
print(f"RH bound at 10^6, valid from x = 2657: sqrt(x) ln x / (8 pi) = {1000 * math.log(X) / (8 * math.pi):.2f}")
print(f"-zeta'/zeta(2): prime powers to 10^6 {lam:.5f}; slope of zeta {slope:.5f}; "
      f"primes only {sum(math.log(p) / p ** 2 for p in primes):.5f}")
print(f"first zero, chased from 0.6 + 14i: {z1.real:.6f} + {z1.imag:.6f}i")
print(f"box 0..1 x 10..20: turns {count.real:.6f}; zero located {where.real:.6f} + {where.imag:.6f}i")
print(f"zeros up to height 100: {len(zeros)}, real parts {min(z.real for z in zeros):.5f} to {max(z.real for z in zeros):.5f}; "
      "heights " + " ".join(f"{z.imag:.3f}" for z in zeros[:6]) + " ...")
print("chart at x = 1.5, 2.5, ..., 29.5, psi: " + row(map(psi, xs)))
print("chart no zeros: " + row(rebuild(x, 0) for x in xs))
print(f"chart {len(zeros)} zero pairs: " + row(rebuild(x, 29) for x in xs))
print(f"largest miss at the half-integers: no zeros {max(abs(psi(x) - rebuild(x, 0)) for x in xs):.2f}, "
      f"29 pairs {(err := max(abs(psi(x) - rebuild(x, 29)) for x in xs)):.2f}; log base 10 at 10^6: {X / 6:.0f}")
print("figure, x = 60 + 120 Re s, y = 230 - 6 Im s: line x 120; heights y " + " ".join(f"{230 - 6 * z.imag:.1f}" for z in zeros[:6]))
assert sum(1 for p in primes if p <= X) == phi(X, 168) + 167 == 78498   # two counts, one number
assert abs(li_series(math.log(X)) - li_integral(math.log(X))) < 1e-3   # two roads to li
assert abs(z1 - where) < 1e-6 and abs(z1 - (0.5 + 14.134725142j)) < 1e-8 and abs(count - 1) < 1e-9  # chase, box, table
assert abs(lam - slope) < 1e-5 and err < 0.5                           # series vs slope; rebuild
print("ALL CHECKS PASS")
