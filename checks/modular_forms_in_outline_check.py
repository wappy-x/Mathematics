# Modular forms in outline -- the check behind the card.  Standard library only.
# Delta = q (1 - q)^24 (1 - q^2)^24 ... is the weight-12, level-1 cusp form, and
# its coefficients are Ramanujan's tau(n).  Here q = e^(2 pi i z), not a modulus.
from math import pi, exp, cos, sin
N, MOD = 40, 1_000_000_007            # series kept to q^40; a prime for ranks

def mul(a, b, m=0):                   # product of two series, cut at q^N
    c = [0] * (N + 1)
    for i, x in enumerate(a):
        for j in range(N + 1 - i):
            c[i + j] += x * b[j]
    return [v % m for v in c] if m else c

def sigma(k, n): return sum(d ** k for d in range(1, n + 1) if n % d == 0)
def eis(c, k): return [1] + [c * sigma(k, n) for n in range(1, N + 1)]
def yn(b): return "yes" if b else "no"
def primes(n): return [p for p in range(2, n + 1) if all(p % d for d in range(2, p))]

P = [1] + [0] * N                     # road 1: multiply out the product
for n in range(1, N + 1):
    for _ in range(24):
        for i in range(N, n - 1, -1):
            P[i] -= P[i - n]          # times (1 - q^n)
tau = [0] + P[:N]                     # Delta = q * P, so tau(n) = P[n - 1]
E4, E6 = eis(240, 3), eis(-504, 5)    # road 2: Eisenstein series
E43, E62 = mul(mul(E4, E4), E4), mul(E6, E6)
D = [(x - y) // 1728 for x, y in zip(E43, E62)]
one = [1] + [0] * N
for _ in range(24): one = [one[i] - (one[i - 1] if i else 0) for i in range(N + 1)]
print("(1 - q)^24 starts", one[:4])
print("E4 starts", E4[:4], "; E6 starts", E6[:4])
print(f"E4^3: q {E43[1]}, q^2 {E43[2]};  E6^2: q {E62[1]}, q^2 {E62[2]}")
print("tau(1..12):", tau[1:13])
print(f"product and (E4^3 - E6^2)/1728 agree to q^{N}:", yn(D == [0] + tau[1:]))

def cexp(w): return complex(exp(w.real) * cos(w.imag), exp(w.real) * sin(w.imag))
def series(c, z): q = cexp(2j * pi * z); return sum(c[n] * q ** n for n in range(N + 1))
def show(w): return f"{w.real:.9f} {'+' if w.imag >= 0 else '-'} {abs(w.imag):.9f}i"
z = complex(0.3, 1.1); w = -1 / z
dz, dw = series([0] + tau[1:], z), series([0] + tau[1:], w)
E2 = eis(-24, 1)
gap, pred = series(E2, w) - z ** 2 * series(E2, z), -6j * z / pi
print(f"z = {show(z)}; -1/z = {show(w)}; |z| = {abs(z):.6f}, |-1/z| = {abs(w):.6f}; |q| = {abs(cexp(2j * pi * z)):.6f}")
print(f"Delta(z) x 1000 = {show(1000 * dz)}")
print(f"Delta(-1/z) x 1000 = {show(1000 * dw)}")
print(f"z^12 Delta(z) x 1000 = {show(1000 * z ** 12 * dz)}")
print(f"weight 11 instead: z^11 Delta(z) x 1000 = {show(1000 * z ** 11 * dz)}")
print(f"E2(-1/z) - z^2 E2(z) = {show(gap)}; -6iz/pi = {show(pred)}")

cop = pp = 0
for m in range(2, N + 1):
    for n in range(m + 1, N // m + 1):
        if all(m % d or n % d for d in range(2, m + 1)):
            assert tau[m * n] == tau[m] * tau[n]; cop += 1
for p in primes(N):
    r = p
    while r * p <= N:
        assert tau[r * p] == tau[p] * tau[r] - p ** 11 * tau[r // p]; pp += 1; r *= p
print(f"Hecke relations to {N}: {cop} coprime pairs, {pp} prime-power steps, all hold")
print(f"mistake, 4 = 2 x 2 not coprime: tau(4) = {tau[4]}, tau(2)^2 = {tau[2] ** 2}")
cong = all((sigma(11, n) - tau[n]) % 691 == 0 for n in range(1, N + 1))
print(f"sigma11(n) - tau(n) divisible by 691 for n = 1..{N}: {yn(cong)}; "
      f"n = 2: {sigma(11, 2)} - ({tau[2]}) = {sigma(11, 2) - tau[2]} = {(sigma(11, 2) - tau[2]) // 691} x 691")
xs = [tau[p] / (2 * p ** 5.5) for p in primes(N)]
deligne = all(tau[p] ** 2 <= 4 * p ** 11 for p in primes(N))
print("tau(p)/(2 p^5.5), p = 2..37:", ", ".join(f"{x:.3f}" for x in xs), "; all in [-1, 1]:", yn(deligne))

def det_mod(M):                       # determinant mod MOD, by elimination
    M, d = [r[:] for r in M], 1
    for c in range(len(M)):
        piv = next((r for r in range(c, len(M)) if M[r][c]), None)
        if piv is None: return 0
        M[c], M[piv] = M[piv], M[c]; d = d * M[c][c] % MOD
        inv = pow(M[c][c], MOD - 2, MOD)
        for r in range(c + 1, len(M)):
            f = M[r][c] * inv % MOD
            M[r] = [(x - f * y) % MOD for x, y in zip(M[r], M[c])]
    return d
dims, counts, pinned = [], [], True
for k in range(0, 37, 2):
    dims.append(k // 12 + (0 if k % 12 == 2 else 1))
    mons = [(a, (k - 4 * a) // 6) for a in range(k // 4 + 1) if (k - 4 * a) % 6 == 0]
    counts.append(len(mons))
    rows = []
    for a, b in mons:
        s = one[:1] + [0] * N
        for _ in range(a): s = mul(s, E4, MOD)
        for _ in range(b): s = mul(s, E6, MOD)
        rows.append(s[:len(mons)])
    pinned = pinned and (not mons or det_mod(rows) != 0)
print("dim M_k, k = 0, 2, ..., 36, by floor(k/12) + [k not 2 mod 12]:", dims)
print("count of products E4^a E6^b of weight k:                    ", counts)
print(f"each space pinned by its first dim coefficients (det mod {MOD} nonzero):", yn(pinned))

e8 = [0] * 4                          # doubled coordinates y = 2x, norm = sum(y^2)/4
def walk(vals, pre, s, sq):
    if len(pre) == 8:
        if s % 4 == 0 and sq % 8 == 0 and 0 < sq <= 24: e8[sq // 8] += 1
        return
    for v in vals:
        if sq + v * v <= 24: walk(vals, pre + [v], s + v, sq + v * v)
walk([-4, -2, 0, 2, 4], [], 0, 0); walk([-3, -1, 1, 3], [], 0, 0)
print(f"E8 vectors of norm 2, 4, 6 by brute force: {e8[1:]}; 240 sigma3(n): {E4[1:4]}")
leech = [65520 * (sigma(11, n) - tau[n]) // 691 for n in range(1, 5)]
print(f"Leech vectors of norm 2, 4, 6, 8 from E12 - (65520/691) Delta: {leech}")
print(f"mistake, E12 alone: 65520 x {sigma(11, 2)}/691 = {65520 * sigma(11, 2) / 691:.4f}, not a whole number")
r4 = [0] * (N + 1)                    # four squares by brute force, against Jacobi's divisor formula
for s in (x * x + y * y + z * z + t * t for x in range(-6, 7) for y in range(-6, 7) for z in range(-6, 7) for t in range(-6, 7)):
    if s <= N: r4[s] += 1
jac = [8 * sum(d for d in range(1, n + 1) if n % d == 0 and d % 4) for n in range(N + 1)]
print(f"four squares, ways for n = 1..8: {r4[1:9]}; 8 x (divisors not divisible by 4): {jac[1:9]}; equal to n = {N}: {yn(r4[1:] == jac[1:])}")
M = 400                               # level 32: q (1 - q^4)^2 (1 - q^8)^2 (1 - q^12)^2 ...
g = [1] + [0] * M
for n in range(1, M // 4 + 1):
    for m in (4 * n, 8 * n):
        for _ in range(2):
            for i in range(M, m - 1, -1): g[i] -= g[i - m]
def f32(z): q = cexp(2j * pi * z); return sum(g[n] * q ** (n + 1) for n in range(M + 1))
u = complex(-1, 2) / 64; c = 32 * u + 1; fu, fv = f32(u), f32(u / c)
print(f"level 32: u = {show(u)}, 32u + 1 = {show(c)}, u/(32u + 1) = {show(u / c)}")
print(f"f(u) = {show(fu)}")
print(f"f(u/(32u + 1)) = {show(fv)}; (32u + 1)^2 f(u) = {show(c ** 2 * fu)}")
print(f"weight 1 instead: (32u + 1) f(u) = {show(c * fu)}")
ap = [g[p - 1] for p in primes(N)[1:]]
pts = [p - sum(1 for x in range(p) for y in range(p) if (y * y - x ** 3 + x) % p == 0) for p in primes(N)[1:]]
print("level 32, weight 2, a_p for p = 3..37:", ap)
print("p minus the points of y^2 = x^3 - x mod p:  ", pts)
print(f"figure, z = ({z.real:.6f}, {z.imag:.6f}), -1/z = ({w.real:.6f}, {w.imag:.6f}), "
      f"rho = (-0.500000, {3 ** 0.5 / 2:.6f}), i = (0, 1)")

assert D == [0] + tau[1:] and tau[1:6] == [1, -24, 252, -1472, 4830]    # two roads
assert abs(dw - z ** 12 * dz) < 1e-12 * abs(dw)                         # weight 12
assert abs(gap - pred) < 1e-9 and abs(dw - z ** 11 * dz) > 1e-4         # E2 and wrong weight fail
assert cong and deligne and tau[4] != tau[2] ** 2 and r4[1:] == jac[1:]   # Jacobi's four squares
assert dims == counts and pinned and e8[1:] == E4[1:4]                  # dimension; E8 count
assert leech[:3] == [0, 196560, 16773120] and ap == pts and abs(fv - c ** 2 * fu) < 1e-9                 # Conway-Sloane; the curve
print("ALL CHECKS PASS")
