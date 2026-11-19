# The zero-free region -- the check behind the card.  Standard library only.  Zeta by
# Euler-Maclaurin and by Borwein's alternating series; the 3-4-1 product by zeta and by its
# series over prime powers; a box around 1 + 14.13i; the widened region of the card, quoted.
import math
def npow(n, s):                       # n^(-s) for a whole number n and a complex s
    m, a = math.exp(-s.real * math.log(n)), s.imag * math.log(n)
    return complex(m * math.cos(a), -m * math.sin(a))
def zeta(s):                          # road 1: head sum + tail integral + end corrections
    N = 60 + int(abs(s.imag)); r = lambda m: math.prod(s + j for j in range(m)) * npow(N, s + m)
    return (sum(npow(n, s) for n in range(1, N)) + N * npow(N, s) / (s - 1) + npow(N, s) / 2
            + r(1) / 12 - r(3) / 720 + r(5) / 30240)
def zeta_b(s, n=50):                  # road 2: Borwein's weighted alternating series
    d, term, acc = [], 1 / n, 0.0
    for i in range(n + 1):
        acc += term; d.append(n * acc); term *= 4 * (n + i) * (n - i) / ((2 * i + 1) * (2 * i + 2))
    tot = sum((-1) ** k * (d[k] - d[n]) * npow(k + 1, s) for k in range(n))
    return -tot / (d[n] * (1 - 2 * npow(2, s)))
X = 10**6                             # the 78,498 primes below a million, by a sieve
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0
for p in range(2, 1001):
    if flag[p]: flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(X + 1) if flag[p]]
def series(sig, t, a):                # sum over p^k of (a0 + a1 cos(k t ln p) + a2 cos(2k t ln p)) / (k p^(k sig))
    tot, low = 0.0, 9.0
    for p in primes:
        k = 1
        while k * sig * math.log(p) < 40:
            th = k * t * math.log(p); b = a[0] + a[1] * math.cos(th) + a[2] * math.cos(2 * th)
            tot += b * math.exp(-k * sig * math.log(p)) / k; low = min(low, b); k += 1
    return tot, low
def secant(a, b):                     # chase a zero of zeta through the complex plane
    for _ in range(60):
        if abs(zeta(b)) > 1e-13: a, b = b, b - zeta(b) * (b - a) / (zeta(b) - zeta(a))
    return b
def turns(c, hw, ht, M=200):          # times zeta winds round 0 along a box edge, anticlockwise
    cs = [c - hw - ht * 1j, c + hw - ht * 1j, c + hw + ht * 1j, c - hw + ht * 1j, c - hw - ht * 1j]
    pts = [a + (b - a) * k / M for a, b in zip(cs, cs[1:]) for k in range(M)] + [cs[0]]
    zs = [zeta(w) for w in pts]
    return sum(math.atan2((w / v).imag, (w / v).real) for v, w in zip(zs, zs[1:])) / (2 * math.pi)
prod341 = lambda sig, t, f=zeta: abs(f(sig)) ** 3 * abs(f(sig + 1j * t)) ** 4 * abs(f(sig + 2j * t))
z1 = secant(0.5 + 14j, 0.5 + 14.3j); t1 = z1.imag; e1, e2 = zeta(1 + 1j * t1), zeta(1 + 2j * t1)
print(f"first zero, chased on the critical line: {z1.real:.6f} + {t1:.6f}i")
cs = lambda z: f"{z.real:.6f} {'-' if z.imag < 0 else '+'} {abs(z.imag):.6f}i"
print(f"zeta(1 + {t1:.6f}i) = {cs(e1)}; size {abs(e1):.6f}, Borwein {abs(zeta_b(1 + 1j * t1)):.6f}")
print(f"zeta(1 + {2 * t1:.6f}i) = {cs(e2)}; size {abs(e2):.6f}, Borwein {abs(zeta_b(1 + 2j * t1)):.6f}")
w_edge, w_line = turns(1 + 1j * t1, 0.25, 0.5), turns(0.5 + 1j * t1, 0.25, 0.5)
print(f"box 0.5 wide, 1 tall: centred on 1 + {t1:.2f}i, turns {round(w_edge)}; centred on 0.5 + {t1:.2f}i, turns {round(w_line)}")
grid = [(abs(zeta(1 + 1j * k / 100)), k / 100) for k in range(100, 4001)]
print(f"smallest |zeta(1 + it)| for t = 1 to 40 in steps of 0.01: {min(grid)[0]:.6f}, at t = {min(grid)[1]:.2f}")
ang = [math.pi * k / 1800 for k in range(3601)]
gap = max(abs(3 + 4 * math.cos(a) + math.cos(2 * a) - 2 * (1 + math.cos(a)) ** 2) for a in ang)
low = min((3 + 4 * math.cos(a) + math.cos(2 * a), k / 10) for k, a in enumerate(ang))
print(f"3 + 4cos + cos2 against 2(1 + cos)^2 on 3601 angles: largest gap below 1e-12; smallest value {abs(low[0]):.6f} at {low[1]:.0f} degrees")
rows = [(sig, prod341(sig, t1)) for sig in (2, 1.5, 1.1, 1.01, 1.001, 1.0001)]
for sig, v in rows:
    print(f"sigma {sig}: zeta(sigma) {zeta(sig).real:.6f}; |zeta(sigma + it)| {abs(zeta(sig + 1j * t1)):.6f}; "
          f"|zeta(sigma + 2it)| {abs(zeta(sig + 2j * t1)):.6f}; product {v:.2f}; (sigma - 1)^3 x product {(sig - 1) ** 3 * v:.6f}")
lim = abs(e1) ** 4 * abs(e2)
print(f"limit |zeta(1 + it)|^4 |zeta(1 + 2it)| = {lim:.6f}")
s341, b341 = series(2, t1, (3, 4, 1))
print(f"sigma 2, log of product: from zeta {math.log(rows[0][1]):.9f}; from 78498 primes {s341:.9f}; smallest bracket {abs(b341):.6f}")
fake = lambda s: zeta(s - 0.5) if abs(s.imag) > 1 else zeta(s)    # zeta slid right: a zero planted at 1 + 14.13i
fz = [(sig, prod341(sig, t1, fake), abs(zeta(sig)) * abs(fake(sig + 1j * t1))) for sig in (1.1, 1.01, 1.001)]
print("planted zero, 3-4-1 product: " + "; ".join(f"sigma {s} {v:.6f}" for s, v, _ in fz))
print("planted zero, 1-1 pair: " + "; ".join(f"sigma {s} {u:.6f}" for s, _, u in fz))
v12, (s12, b12) = zeta(2).real * abs(zeta(2 + 1j * t1)) ** 2, series(2, t1, (1, 2, 0))
print(f"1 + 2cos dips to {min(1 + 2 * math.cos(a) for a in ang):.6f}; zeta(2)|zeta(2 + it)|^2 = {v12:.6f}; "
      f"from 78498 primes {math.exp(s12):.6f}, smallest bracket {b12:.6f}")
print(f"sigma 0.5, off the series: product {prod341(0.5, t1):.6f}")
R = 5.558691                          # quoted: no zero with sigma >= 1 - 1/(R ln|t|), |t| >= 2
wid = lambda t: 1 / (R * math.log(t))
print("region width 1/(R ln t): " + "; ".join(f"t = {n} {wid(t):.6f}" for n, t in
      ((f"{t1:.2f}", t1), ("1000", 1e3), ("10^6", 1e6), ("3x10^12", 3e12))) + f"; edge at t1 {1 - wid(t1):.6f}")
g_e, g_1, r_e, r_1 = X ** -wid(t1), X ** -0.5, abs(complex(1 - wid(t1), t1)), abs(z1)   # x^(beta - 1), and |rho|
print(f"wave over x at x = 10^6, x^(beta - 1)/|rho|, one zero and its pair: region's edge {g_e / r_e:.6f}, {2 * g_e / r_e:.6f}; "
      f"first zero {g_1 / r_1:.6f}, {2 * g_1 / r_1:.6f}; x^(beta - 1) alone {g_e:.6f}, {g_1:.6f}")
ts = range(1, 41)
print("chart |zeta(1 + it)|, t = 1..40: " + ", ".join(f"{abs(zeta(1 + 1j * t)):.2f}" for t in ts))
print("chart |zeta(1/2 + it)|, t = 1..40: " + ", ".join(f"{abs(zeta(0.5 + 1j * t)):.2f}" for t in ts))
fig = [2, 3, 5, 10, 20, 30, 40, 50]
print("figure, x = 60 + 300 sigma, y = 260 - 5 t: boundary " + " ".join(f"({60 + 300 * (1 - wid(t)):.1f},{260 - 5 * t:.1f})"
      for t in fig) + f"; edge point (360.0,{260 - 5 * t1:.1f}); first zero (210.0,{260 - 5 * t1:.1f})")
zs40 = [secant(0.5 + 1j * a, 0.5 + 1j * (a + 0.2)).imag for a in (14, 20.9, 24.9, 30.3, 32.8, 37.5)]
print("zeros below 40, chased on the critical line: " + ", ".join(f"{t:.2f}" for t in zs40))
fake4 = lambda s: zeta(s - 0.4) if abs(s.imag) > 1 else zeta(s)   # try: the zero planted at 0.9 + 14.13i instead
w15 = 1 / (5.573412 * math.log(t1))                                # try: the 2015 constant
print(f"try: zero planted at 0.9 + {t1:.2f}i, product at sigma 1.001 {prod341(1.001, t1, fake4):.6f}; "
      f"R = 5.573412: width at t1 {w15:.6f}, clear above {1 - w15:.6f}")
assert abs(z1 - (0.5 + 14.134725142j)) < 1e-8 and abs(zeta_b(z1)) < 1e-8          # chase vs table vs road 2
assert abs(abs(zeta_b(1 + 1j * t1)) - abs(e1)) < 1e-9 and abs(e1) > 0.3          # no zero at 1 + 14.13i, two roads
assert abs(w_edge) < 1e-6 and abs(w_line - 1) < 1e-6                             # box: none at the edge, one inside
assert gap < 1e-12 and abs(math.log(rows[0][1]) - s341) < 1e-6 and b341 > -1e-12   # identity; zeta vs prime series
assert all(v >= 1 for _, v in rows) and abs((1e-4) ** 3 * rows[-1][1] - lim) < 1e-3 * lim   # >= 1; the limit
assert fz[-1][1] < 0.01 and v12 < 1 and abs(math.exp(s12) - v12) < 1e-6  # planted zero; 1 + 2cos fails
print("ALL CHECKS PASS")
