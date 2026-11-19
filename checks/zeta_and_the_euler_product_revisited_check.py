# Zeta of a complex variable: the check behind the card.  Standard library only.
# Zeta is computed two ways: Euler-Maclaurin with Bernoulli terms (cut-off 60),
# and a long sum to 100,000 with the integral tail.  Primes come from a sieve.
import math

def cpow(n, s):  # n^(-s) = e^(-sigma log n) (cos(t log n) - i sin(t log n))
    L = math.log(n); r = math.exp(-s.real * L)
    return complex(r * math.cos(s.imag * L), -r * math.sin(s.imag * L))

BERN = [1/6, -1/30, 1/42, -1/30, 5/66, -691/2730]  # B_2 .. B_12

def zeta_em(s, N=60):  # returns zeta(s) and zeta'(s), Euler-Maclaurin
    s = complex(s); z = complex(0); d = complex(0)
    for n in range(1, N):
        w = cpow(n, s); z += w; d -= math.log(n) * w
    LN = math.log(N); wN = cpow(N, s)
    z += N * wN / (s - 1) + wN / 2
    d += -LN * N * wN / (s - 1) - N * wN / ((s - 1) * (s - 1)) - LN * wN / 2
    for k in range(1, 7):
        P = complex(1); dP = complex(0)
        for j in range(2 * k - 1):
            dP = dP * (s + j) + P; P = P * (s + j)
        c = BERN[k - 1] / math.factorial(2 * k) * N ** (1 - 2 * k)
        z += c * P * wN; d += c * wN * (dP - LN * P)
    return z, d

def zeta_long(s, M=100000):  # sum to M, plus M^(1-s)/(s-1) - M^(-s)/2
    s = complex(s); z = complex(0)
    for n in range(1, M + 1):
        z += cpow(n, s)
    wM = cpow(M, s)
    return z + M * wM / (s - 1) - wM / 2

def f(x, k=6): return f"{x:.{k}f}"
def row(xs, k=2): return ", ".join(f(x, k) for x in xs)

X = 10 ** 6
sieve = bytearray([1]) * (X + 1); sieve[0] = sieve[1] = 0
for p in range(2, 1001):
    if sieve[p]:
        sieve[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(X + 1) if sieve[p]]
print(f"primes below 10^6 by sieve: {len(primes)}")
assert len(primes) == 78498

def euler(sg, P):
    prod = 1.0
    for p in primes:
        if p > P: break
        prod *= 1 / (1 - p ** -sg)
    return prod

part = 0.0
for n in range(1, 1001): part += 1 / n ** 2
lo, hi = part + 1 / 1001, part + 1 / 1000
z2 = zeta_em(2)[0].real
print(f"zeta(2): 1000 terms {f(part, 8)}; tail bracket [{f(lo, 8)}, {f(hi, 8)}]")
e1000, eX = euler(2, 1000), euler(2, X)
print(f"zeta(2): product, 168 primes {f(e1000, 8)}; 78498 primes {f(eX, 8)}; "
      f"pi^2/6 {f(math.pi ** 2 / 6, 8)}; Euler-Maclaurin {f(z2, 8)}")
assert lo < math.pi ** 2 / 6 < hi and abs(z2 - math.pi ** 2 / 6) < 1e-12
assert e1000 < eX < z2 and z2 - eX < 1.0 / X

z11 = zeta_em(1.1)[0].real; l11 = zeta_long(1.1).real
print(f"zeta(1.1): Euler-Maclaurin {f(z11)}; long sum {f(l11)}; bracket 10 < zeta(1.1) < 11")
assert abs(z11 - l11) < 1e-7 and 10 < z11 < 11

sgs = [1 + k / 10 for k in range(1, 11)]
zs = [zeta_em(sg)[0].real for sg in sgs]
print("chart, sigma = 1.1 .. 2.0, lower 1/(sigma-1): " + row([1 / (sg - 1) for sg in sgs]))
print("chart, zeta(sigma): " + row(zs))
print("chart, upper sigma/(sigma-1): " + row([sg / (sg - 1) for sg in sgs]))
for sg, z in zip(sgs, zs):
    assert 1 / (sg - 1) < z < sg / (sg - 1)

gN = 0.0
for n in range(1, X + 1): gN += 1 / n
gamma = gN - math.log(X) - 1 / (2 * X) + 1 / (12 * X * X)
near = [1.1, 1.01, 1.001]
zn = [zeta_em(sg)[0].real for sg in near]
print("pole: (sigma-1) zeta(sigma) at 1.1, 1.01, 1.001: " + row([(sg - 1) * z for sg, z in zip(near, zn)], 6))
print("zeta(sigma) - 1/(sigma-1) at 1.1, 1.01, 1.001: " + row([z - 1 / (sg - 1) for sg, z in zip(near, zn)], 6))
print(f"Euler's constant gamma from 1 + 1/2 + ... + 1/N - log N, N = 10^6: {f(gamma)}")
assert abs(zn[2] - 1 / 0.001 - gamma) < 1e-4

def vm(sg, prime_powers=True):  # sum of Lambda(n) n^(-sigma) for n <= 10^6
    tot = 0.0
    for p in primes:
        q = p
        while q <= X:
            tot += math.log(p) * q ** -sg
            if not prime_powers: break
            q *= p
    return tot

z, d = zeta_em(2)
ld2, vm2, vp2 = (-d / z).real, vm(2), vm(2, False)
print(f"-zeta'/zeta(2): prime powers to 10^6 {f(vm2, 5)}; slope of zeta {f(ld2, 5)}; primes only {f(vp2, 5)}")
assert 0 < ld2 - vm2 < 2e-6
lds = [(-zeta_em(sg)[1] / zeta_em(sg)[0]).real for sg in near]
print("-zeta'/zeta(sigma) at 1.1, 1.01, 1.001: " + row(lds, 6))
print("1/(sigma-1) - gamma at 1.1, 1.01, 1.001: " + row([1 / (sg - 1) - gamma for sg in near], 6))
assert all(abs(L - (1 / (sg - 1) - gamma)) < 3 * (sg - 1) for L, sg in zip(lds, near))

ts = [1, 10, 100, 1000]
zc = [zeta_em(complex(1.1, t), max(60, t)) for t in ts]
floor = zeta_em(2.2)[0].real / z11
print(f"floor zeta(2.2)/zeta(1.1) {f(floor)}, ceiling zeta(1.1) {f(z11)}")
print("|zeta(1.1 + it)| at t = 1, 10, 100, 1000: " + row([abs(z) for z, d in zc], 6))
print("|zeta'/zeta(1.1 + it)| at t = 1, 10, 100, 1000: " + row([abs(d / z) for z, d in zc], 6))
for z, d in zc:
    assert floor < abs(z) < z11 and abs(d / z) < lds[0]

tl = [10, 100, 1000]
em1 = [abs(zeta_em(complex(1, t), max(60, t))[0]) for t in tl]
lg1 = [abs(zeta_long(complex(1, t))) for t in tl]
print("|zeta(1 + it)| at t = 10, 100, 1000, Euler-Maclaurin: " + row(em1, 6))
print("|zeta(1 + it)| at t = 10, 100, 1000, long sum: " + row(lg1, 6))
print("bound log t + 5.5 at t = 10, 100, 1000: " + row([math.log(t) + 5.5 for t in tl]))
for a, b, t in zip(em1, lg1, tl):
    assert abs(a - b) < 1e-6 and a < math.log(t) + 5.5

eu11, vm11 = euler(1.1, X), vm(1.1)
print(f"mistake, Euler product at 1.1 over primes to 10^6: {f(eu11)}, not {f(z11)}")
print(f"mistake, prime powers to 10^6 at 1.1: {f(vm11)}, not {f(lds[0])}")
h = 0.0
for n in range(1, 1001): h += n ** -0.5
zh = zeta_em(0.5)[0].real
print(f"mistake, the series at s = 1/2, 1000 terms: {f(h)}; zeta(1/2) {f(zh)}, inside [-2, -1]")
assert eu11 < z11 - 1 and vm11 < lds[0] - 1 and -2 < zh < -1
e11 = euler(1.1, 1000)
print(f"try: zeta(1.01) {f(zn[1])}; Euler product at 1.1, primes to 1000: {f(e11)}")
assert 100 < zn[1] < 101 and e11 < eu11
print(f"gaps at 1.1: zeta - floor {f(z11 - 10)}, ceiling - zeta {f(11 - z11)}, -zeta'/zeta - prediction "
      f"{f(lds[0] - 1 / 0.1 + gamma)}; cut product short by {f(100 * (1 - eu11 / z11), 1)} percent; 6/pi^2 {f(6 / math.pi ** 2)}")
print("ALL CHECKS PASS")
