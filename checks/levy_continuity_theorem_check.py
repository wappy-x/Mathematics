# Levy's continuity theorem -- the check behind the card.  Standard library only.
# Binomial(n, 2/n) fingerprints against the Poisson(2)'s; three roads to the masses
# (counting, inversion of the fingerprint, simulation); tightness; three traps.
import math

LAM, P_REQ, N_REQ, SEED = 2.0, 0.002, 1000, 20261115   # 1,000 requests a minute, 0.2% fail each

def cmul(a, b): return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])
def cexp(x, y): r = math.exp(x); return (r * math.cos(y), r * math.sin(y))
def cpow(z, n):                                 # z^n by repeated squaring
    out = (1.0, 0.0)
    while n > 0:
        if n & 1: out = cmul(out, z)
        z = cmul(z, z); n >>= 1
    return out
def fp_binom(n, p, t): return cpow((1.0 - p + p * math.cos(t), p * math.sin(t)), n)
def fp_pois(lam, t): return cexp(lam * (math.cos(t) - 1.0), lam * math.sin(t))
def gap(a, b): return math.hypot(a[0] - b[0], a[1] - b[1])
def binom_pmf(n, p, kmax):                     # counting road: the ratio recurrence
    out = [(1.0 - p) ** n]
    for k in range(kmax): out.append(out[-1] * (n - k) / (k + 1) * p / (1.0 - p))
    return out
def pois_pmf(lam, kmax): return [math.exp(-lam) * lam ** k / math.factorial(k) for k in range(kmax + 1)]
def invert(fp, M, k):                          # (1/2pi) int_{-pi}^{pi} fp(t) e^{-itk} dt, M points
    s = 0.0
    for j in range(M):
        t = -math.pi + 2.0 * math.pi * j / M; f = fp[j]
        s += f[0] * math.cos(t * k) + f[1] * math.sin(t * k)
    return s / M
def simpson(f, a, b, m=2000):
    h = (b - a) / m; s = f(a) + f(b)
    for i in range(1, m): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0
def tail_bound(re_fp, u): return simpson(lambda t: 1.0 - re_fp(t), -u, u) / u
def erf(x):                                    # 2/sqrt(pi) e^{-x^2} sum 2^k x^{2k+1}/(1*3*...*(2k+1))
    term = x; s = x; k = 0
    while term > 1e-17 * s: k += 1; term *= 2.0 * x * x / (2 * k + 1); s += term
    return 2.0 / math.sqrt(math.pi) * math.exp(-x * x) * s
STATE = [SEED]
def splitmix():
    STATE[0] = (STATE[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = STATE[0]; z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return z ^ (z >> 31)
def uniform(): return ((splitmix() >> 11) + 1) / 9007199254740992.0   # in (0, 1]
def c6(z): return f"{z[0]:+.6f} {z[1]:+.6f}i"

print("Levy continuity check: Binomial(n, 2/n) fingerprints against the Poisson(2)'s")
print("fingerprint at t = 1:")
lim1 = fp_pois(LAM, 1.0)
for n in (10, 100, 1000, 10000):
    z = fp_binom(n, LAM / n, 1.0)
    print(f"  n={n:<6d} {c6(z)}   gap {gap(z, lim1):.6f}   n x gap {n * gap(z, lim1):.4f}")
print(f"  Poisson  {c6(lim1)}")
w = (math.cos(1.0) - 1.0, math.sin(1.0))
pred = math.hypot(*lim1) * LAM ** 2 * (2.0 - 2.0 * math.cos(1.0)) / 2.0
print(f"by hand: e^i {c6((math.cos(1.0), math.sin(1.0)))}  lam(e^i - 1) {c6((LAM * w[0], LAM * w[1]))}  |fp| {math.exp(LAM * w[0]):.6f}")
print(f"by hand: base n=1000 {c6((1.0 + P_REQ * w[0], P_REQ * w[1]))}  predicted n x gap {pred:.4f}  at n=1000 {pred / 1000:.6f}")
assert abs(10000 * gap(fp_binom(10000, LAM / 10000, 1.0), lim1) - pred) < 0.001
ts = [-math.pi + 2.0 * math.pi * j / 2000 for j in range(2001)]
worst = {}
for n in (10, 100, 1000):
    worst[n] = max(gap(fp_binom(n, LAM / n, t), fp_pois(LAM, t)) for t in ts)
    print(f"worst gap over all t, n={n:<5d} {worst[n]:.6f}   n x gap {n * worst[n]:.4f}")
assert worst[1000] < worst[100] < worst[10] and abs(1000 * worst[1000] / (100 * worst[100]) - 1) < 0.02

M = 1024
fpb = [fp_binom(N_REQ, P_REQ, -math.pi + 2.0 * math.pi * j / M) for j in range(M)]
fpp = [fp_pois(LAM, -math.pi + 2.0 * math.pi * j / 64) for j in range(64)]
cnt, pois = binom_pmf(N_REQ, P_REQ, 6), pois_pmf(LAM, 6)
print("k  counting n=1000  inverted n=1000  Poisson   inverted Poisson (64 points)")
for k in range(7):
    ib, ip = invert(fpb, M, k), invert(fpp, 64, k)
    print(f"{k}  {cnt[k]:.6f}        {ib:.6f}         {pois[k]:.6f}  {ip:.6f}")
    assert abs(ib - cnt[k]) < 1e-12 and abs(ip - pois[k]) < 1e-12
print(f"aliasing bound for 64 points: P(N >= 64) = {sum(pois_pmf(LAM, 100)[64:]):.1e}")

tails = {}
for n in (10, 100, 1000):
    tails[n] = 1.0 - sum(binom_pmf(n, LAM / n, 5))
tails[0] = 1.0 - sum(pois[:6])
print(f"P(6 or more failures): n=10 {tails[10]:.6f}  n=100 {tails[100]:.6f}  n=1000 {tails[1000]:.6f}  Poisson {tails[0]:.6f}")
print(f"paging gap, Poisson minus n=1000: {tails[0] - tails[1000]:.6f}   one minute in {1 / tails[1000]:.1f} (n=1000), {1 / tails[0]:.1f} (Poisson)")
MIN, hits, total = 200000, 0, 0
log_q = math.log(1.0 - P_REQ)
for _ in range(MIN):                           # simulation road: jump from failure to failure
    pos, c = -1, 0
    while True:
        pos += 1 + int(math.log(uniform()) / log_q)
        if pos >= N_REQ: break
        c += 1
    hits += c >= 6; total += c
se = math.sqrt(tails[1000] * (1 - tails[1000]) / MIN)
print(f"simulation, {MIN} minutes, seed {SEED}: mean {total / MIN:.4f}  P(6 or more) {hits / MIN:.6f}  (s.e. {se:.6f})")
assert abs(hits / MIN - tails[1000]) < 4 * se and abs(total / MIN - 2.0) < 0.02

U = 0.3
print(f"tightness, u = {U}: tail bound (1/u) int (1 - Re fp) dt, against P(count > 2/u = {2 / U:.2f})")
for n in (10, 100, 1000):
    b = tail_bound(lambda t: fp_binom(n, LAM / n, t)[0], U)
    true = 1.0 - sum(binom_pmf(n, LAM / n, int(2 / U)))
    print(f"  n={n:<5d} bound {b:.6f}   true {true:.6f}   ratio {b / true:.1f}")
    assert true <= b < 0.2
bp = tail_bound(lambda t: fp_pois(LAM, t)[0], U)
tpp = 1.0 - sum(pois_pmf(LAM, int(2 / U)))
print(f"  Poisson  bound {bp:.6f}   true {tpp:.6f}   ratio {bp / tpp:.1f}")
assert abs(bp - (2 * U ** 2 - 94 / 60 * U ** 4)) < 0.0015   # moments: E[N^2] = 6, E[N^4] = 94

print("trap 1, chance fixed at 0.002 while n grows:")
for n in (1000, 10000, 100000):
    z = fp_binom(n, P_REQ, 1.0)
    print(f"  n={n:<6d} |fp(1)| {math.hypot(*z):.6f}   P(5 or fewer) {sum(binom_pmf(n, P_REQ, 5)):.6f}")
assert math.hypot(*fp_binom(100000, P_REQ, 1.0)) < 1e-30 and abs(fp_binom(100000, P_REQ, 2 * math.pi)[0] - 1) < 1e-9
print("trap 2, normal laws of variance n:")
for n in (1, 100, 10000):
    pin = erf(5.0 / math.sqrt(2.0 * n))
    b = tail_bound(lambda t: math.exp(-n * t * t / 2.0), U)
    print(f"  n={n:<6d} fp(0.1) {math.exp(-n * 0.005):.6f}   P(|X| <= 5) {pin:.6f}   tail bound {b:.6f}")
    assert abs(pin - math.erf(5.0 / math.sqrt(2.0 * n))) < 1e-12   # library cross-check
print("trap 3, Poisson(2) with chance 0.9, else the value n:")
fps = []
for n in (20, 200, 2000):
    z = (0.9 * lim1[0] + 0.1 * math.cos(n), 0.9 * lim1[1] + 0.1 * math.sin(n))
    zk = [sum(0.9 * q * f(k) for k, q in enumerate(pois_pmf(LAM, 60))) + 0.1 * f(n) for f in (math.cos, math.sin)]
    F = lambda x: 0.9 * sum(pois_pmf(LAM, min(x, 60))) + 0.1 * (n <= x)
    print(f"  n={n:<5d} fp(1) {c6(z)}   F_n(10) {F(10):.6f}   F_n(1000) {F(1000):.6f}")
    assert gap(z, zk) < 1e-12 and abs(F(1000) - (1.0 if n <= 1000 else 0.9)) < 1e-12   # fingerprint = sum over masses
    assert abs(F(10) - 0.9 + 0.9 * sum(pois_pmf(LAM, 60)[11:])) < 1e-12
    fps.append(z)
assert gap(fps[0], fps[1]) > 0.05 and gap(fps[0], fps[2]) > 0.05   # the fingerprints wander: no limit

print("chart, real part of the fingerprint at t = 0, 0.25, ..., 3:")
for name, f in (("n=5 ", lambda t: fp_binom(5, 0.4, t)), ("n=20", lambda t: fp_binom(20, 0.1, t)),
                ("Pois", lambda t: fp_pois(LAM, t))):
    print("  " + name + " " + ", ".join(f"{f(0.25 * j)[0]:.2f}" for j in range(13)))
print("ALL CHECKS PASS")
