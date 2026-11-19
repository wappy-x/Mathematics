# Prime number theorem with an error term: psi(x) - x and pi(x) - Li(x) by exact counts,
# the contour of the proof checked on zeta itself, and the choice of the cut-off height T.
import math
from itertools import compress
N, M = 10**7, 10**6
sv = bytearray([1]) * (N + 1); sv[0] = sv[1] = 0
for p in range(2, math.isqrt(N) + 1):
    if sv[p]: sv[p*p::p] = bytes(len(range(p*p, N + 1, p)))
primes = list(compress(range(N + 1), sv))
print(f"sieve to 10^7: {len(primes)} primes")
def ksum(vals):                       # Kahan summation, the same in both languages
    s = c = 0.0
    for v in vals:
        y = v - c; t = s + y; c = (t - s) - y; s = t
    return s
def npow(p, x):                       # how many powers p, p^2, ... are <= x
    k, q = 1, p
    while q * p <= x: q *= p; k += 1
    return k
def simpson(f, a, b, n=20000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def Li(x):                            # offset log integral, t = e^u: area under e^u/u
    return simpson(lambda u: math.exp(u) / u, math.log(2), math.log(x))
def Li_series(x):                     # li(x) - li(2) by its power series in log x; gamma cancels
    L, l2 = math.log(x), math.log(2)
    s, a, b = math.log(L) - math.log(l2), 1.0, 1.0
    for n in range(1, 120):
        a *= L / n; b *= l2 / n; s += (a - b) / n
    return s
XS = [10**k for k in range(2, 8)]
rows = {}
print("       x    pi(x)    x/log x        Li(x)          psi(x)    psi - x   theta - x")
for x in XS:
    ps = [p for p in primes if p <= x]
    th, psi, li = ksum(math.log(p) for p in ps), ksum(math.log(p) * npow(p, x) for p in ps), Li(x)
    rows[x] = (len(ps), th, psi, li)
    print(f"{x:8d} {len(ps):8d} {x / math.log(x):10.3f} {li:12.3f} {psi:15.3f} {psi - x:10.3f} {th - x:11.3f}")
    assert abs(li - Li_series(x)) < 1e-6 * li            # road 2 for Li
    if x >= 10**5: assert abs(psi / x - 1) < 1e-3          # evidence, not proof
print("chart psi/x:", ", ".join(f"{rows[x][2] / x:.4f}" for x in XS))
print("chart pi/(x/log x):", ", ".join(f"{rows[x][0] * math.log(x) / x:.4f}" for x in XS))
print("chart pi/Li:", ", ".join(f"{rows[x][0] / rows[x][3]:.4f}" for x in XS))
pi6, th6, psi6, li6 = rows[M]
L6 = math.log(M); y6 = M / L6
ps6 = [p for p in primes if p <= M]
thc, I1 = 0.0, 0.0                    # integral of theta(t)/(t log^2 t), exact on the staircase
for i, p in enumerate(ps6):
    thc += math.log(p); q = ps6[i + 1] if i + 1 < len(ps6) else M
    I1 += thc * (1 / math.log(p) - 1 / math.log(q))
J = simpson(lambda u: math.exp(u) / u**2, math.log(2), L6)   # integral of 1/log^2 t
pi_abel = th6 / L6 + I1
print(f"worked, log x = {L6:.4f}, sqrt(log x) = {math.sqrt(L6):.4f}, x/log^2 x = {y6 / L6:.3f}")
print(f"worked, pi = x/log x + (Li - x/log x) + (pi - Li) = {y6:.3f} + {li6 - y6:.3f} + {pi6 - li6:.3f}")
print(f"worked, theta - x = (psi - x) - (psi - theta) = {psi6 - M:.3f} - {psi6 - th6:.3f} = {th6 - M:.3f}")
rhs = (th6 - M) / L6 + (I1 - J) + 2 / math.log(2)
print(f"worked, pi - Li = {(th6 - M) / L6:.3f} + {I1 - J:.3f} + {2 / math.log(2):.3f} = {rhs:.3f}")
print(f"worked, pi by partial summation from theta = {pi_abel:.3f}")
assert abs(pi_abel - pi6) < 1e-6 and abs(rhs - (pi6 - li6)) < 1e-6
lam = [0.0] * (M + 1)                 # Chebyshev's identity: sum of psi(x/n) = log of x factorial
for p in ps6:
    q = p
    while q <= M: lam[q] = math.log(p); q *= p
cum = [0.0] * (M + 1)
for m in range(1, M + 1): cum[m] = cum[m - 1] + lam[m]
lhs = sum(cum[M // n] for n in range(1, M + 1)); logfact = sum(math.log(m) for m in range(2, M + 1))
print(f"Chebyshev identity at 10^6: sum psi(x/n) = {lhs:.3f}, log(x!) = {logfact:.3f}")
assert abs(lhs - logfact) < 1e-3 and abs(cum[M] - psi6) < 1e-6
NB = 60; d, term, acc = [], 1.0 / NB, 0.0   # Borwein's algorithm for zeta(s), Re s > 0
for i in range(NB + 1):
    if i: term *= 4 * (NB + i - 1) * (NB - i + 1) / ((2 * i) * (2 * i - 1))
    acc += term; d.append(NB * acc)
def cpow(b, s):                       # b^(-s) for real b > 0
    lb = math.log(b); m = math.exp(-s.real * lb)
    return complex(m * math.cos(-s.imag * lb), m * math.sin(-s.imag * lb))
def zeta(s):
    acc = complex(0, 0)
    for k in range(NB): acc += ((-1)**k * (d[k] - d[NB])) * cpow(k + 1, s)
    w = (1 - 2 * cpow(2, s)) * d[NB]; w2 = w.real**2 + w.imag**2
    return -acc * complex(w.real / w2, -w.imag / w2)
c = 1 + 1 / L6; T = math.exp(math.sqrt(L6)); s1 = 1 - 1 / (2 * 5.558691 * math.log(T))
print(f"contour at 10^6: c = {c:.6f}, T = exp(sqrt(log x)) = {T:.4f}, sigma1 = {s1:.6f}; 1/(2R) = {1 / (2 * 5.558691):.6f}, 1/sqrt(2R) = {1 / math.sqrt(2 * 5.558691):.6f}")
def Z(t):                             # Hardy's Z: real on the critical line
    th = t / 2 * math.log(t / (2 * math.pi)) - t / 2 - math.pi / 8 + 1 / (48 * t) + 7 / (5760 * t**3)
    z = zeta(complex(0.5, t)); return z.real * math.cos(th) - z.imag * math.sin(th)
zeros, t = [], 10.0
while t + 0.1 <= 45:                  # up to the top of the figure
    if Z(t) * Z(t + 0.1) < 0:
        a, b = t, t + 0.1
        for _ in range(45): m = (a + b) / 2; a, b = (a, m) if Z(a) * Z(m) < 0 else (m, b)
        zeros.append((a + b) / 2)
    t += 0.1
print("zeros on Re s = 1/2 up to height 45, heights:", " ".join(f"{z:.6f}" for z in zeros))
assert len(zeros) == 8 and zeros[6] < T < zeros[7] and abs(zeros[0] - 14.134725) < 1e-5
path = [complex(c, -T + 2 * T * i / 8000) for i in range(8001)] + [complex(c - (c - s1) * i / 40, T) for i in range(1, 41)]
path += [complex(s1, T - 2 * T * i / 8000) for i in range(1, 8001)] + [complex(s1 + (c - s1) * i / 40, -T) for i in range(1, 41)]
vals = [zeta(s) for s in path]
turn = sum(math.atan2((w * v.conjugate()).imag, (w * v.conjugate()).real) for v, w in zip(vals, vals[1:])) / (2 * math.pi)
print(f"winding of zeta round the rectangle: {turn:.6f} turns (zeros inside minus poles inside)")
assert abs(turn + 1) < 1e-6
h, best = 1e-4, (0.0, 0.0)
for i in range(781):
    s = complex(s1, 2 + (T - 2) * i / 780)
    r = abs((zeta(s + h) - zeta(s - h)) / (2 * h) / zeta(s))
    if r > best[0]: best = (r, s.imag)
print(f"max |zeta'/zeta| on the left side, 2 <= t <= T: {best[0]:.4f} at t = {best[1]:.2f}; (log T)^2 = {math.log(T)**2:.4f}")
assert best[0] < math.log(T)**2
r0 = abs((zeta(complex(s1 + h, 0)) - zeta(complex(s1 - h, 0))) / (2 * h) / zeta(complex(s1, 0)))
print(f"|zeta'/zeta| on the left side at t = 0, next to the pole: {r0:.2f}; 2R log T = {2 * 5.558691 * math.log(T):.2f}")
def sci(v):
    e = math.floor(math.log10(v)); m = v / 10**e
    if round(m, 3) >= 10: m /= 10; e += 1
    return f"{m:.3f}e{e}"
for k in (6, 20, 100):                # relative error bound of the proof, every constant set to 1
    L = k * math.log(10); out = []
    for lt in (math.log(100), math.sqrt(L), L / 2):
        out.append(L * L / math.exp(lt) + lt**3 * math.exp(-L / lt))
    print(f"shape, x = 10^{k}: T = 100 {sci(out[0])}, T = exp(sqrt(log x)) {sci(out[1])}, T = sqrt(x) {sci(out[2])}")
assert out[1] < 1 < min(out[0], out[2])
amp = 2 * M / abs(complex(1, zeros[0])); wave = -2 * (cpow(M, complex(-1, -zeros[0])) / complex(1, zeros[0])).real
print(f"broken: zeros at 1 +- {zeros[0]:.6f}i, wave amplitude at 10^6 {amp:.3f}, wave now {wave:.3f}")
print("broken: pi - x/log x at 10^5, 10^6, 10^7:", " ".join(f"{rows[x][0] - x / math.log(x):.3f}" for x in XS[3:]))
print("broken: pi - Li at 10^5, 10^6, 10^7:", " ".join(f"{rows[x][0] - rows[x][3]:.3f}" for x in XS[3:]))
print(f"try: share of primes near 2^1024 1/{1024 * math.log(2):.2f}, among odd numbers 1/{512 * math.log(2):.2f}")
fx = lambda sg: 60 + 300 * sg; fy = lambda tt: 170 - 3.5 * tt
bd = " ".join(f"{fx(1 - 1 / (5.558691 * math.log(tt))):.1f}" for tt in (2, 3, 5, 8, 12, 20, 30, 45))
print(f"figure, X = 60 + 300 Re s, Y = 170 - 3.5 Im s: c {fx(c):.1f}, sigma1 {fx(s1):.1f}, top {fy(T):.1f}, bottom {fy(-T):.1f}")
print("figure, zeros y " + " ".join(f"{fy(z):.1f}" for z in zeros) + "; boundary x at t = 2 3 5 8 12 20 30 45: " + bd)
print("ALL CHECKS PASS")
