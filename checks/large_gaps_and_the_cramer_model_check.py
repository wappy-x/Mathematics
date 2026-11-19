# Large prime gaps and the Cramer model -- the check behind the card.
# Standard library only.  Road one sieves every prime up to 10^8 and finds the record
# gaps.  Road two tests the endpoints with Miller-Rabin and re-sieves the 1,132-gap
# by every prime up to its square root.  Road three is the coin-flip model, by formula
# and by simulation.  Gaps above 10^8 are quoted from the table of Oliveira e Silva,
# Herzog and Pardi (2014), labelled so.
import math, itertools
def add(xs):                                      # plain left-to-right float sum
    t = 0.0
    for v in xs: t += v
    return t
def sci(v):                                       # 4.829 x 10^13
    m, e = f"{v:.3e}".split("e")
    return f"{m} x 10^{int(e)}"
N = 10**8
s = bytearray([1]) * (N + 1); s[0] = s[1] = 0
for i in range(2, int(N**0.5) + 1):
    if s[i]:
        s[i * i::i] = bytes(len(range(i * i, N + 1, i)))
primes = list(itertools.compress(range(N + 1), s))
def is_prime(n):                                  # Miller-Rabin, exact below 3.3 x 10^24
    if n < 2: return False
    B = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
    for b in B:
        if n % b == 0: return n == b
    d, r = n - 1, 0
    while d % 2 == 0: d //= 2; r += 1
    for b in B:
        x = pow(b, d, n)
        if x in (1, n - 1): continue
        for _ in range(r - 1):
            x = x * x % n
            if x == n - 1: break
        else: return False
    return True
P, g = 1693182318746371, 1132
mr = [n for n in range(P, P + g + 1) if is_prime(n)]
seg = bytearray([1]) * (g + 1)                    # road two: sieve [P, P + g]
root = math.isqrt(P + g)
for q in primes:
    if q > root: break
    seg[(-P) % q::q] = bytes(len(range((-P) % q, g + 1, q)))
sv = [P + i for i in range(g + 1) if seg[i]]
L = math.log(P)
print(f"p = {P:,}: primes in [p, p + {g:,}] by Miller-Rabin: {', '.join(f'{v:,}' for v in mr)}; by sieve to {root:,}: {len(sv)} found; composites between {g-1:,}")
print(f"log p = {L:.4f}; (log p)^2 = {L*L:.2f}; merit g / log p = {g/L:.2f}; g / (log p)^2 = {g/(L*L):.4f}")
gstar = L * (L - math.log(L))
print(f"model: chance a gap is >= {g:,} = e^-{g/L:.2f} = {sci(math.exp(-g/L))}; primes below p about {sci(P/L)};"
      f" expected such gaps {P/L*math.exp(-g/L):.2f}; predicted largest gap log p (log p - log log p) = {gstar:.1f}")
eg = 2 * math.exp(-0.5772156649015329)
print(f"Granville 2e^-gamma = {eg:.4f}; 2e^-gamma (log p)^2 = {eg*L*L:.1f}")
print(f"base-10 slip: (log10 p)^2 = {math.log10(P)**2:.1f}; g / (log10 p)^2 = {g/math.log10(P)**2:.2f}")
print("quoted from the table: every maximal gap below 4 x 10^18 checked (2014); the gap of 1,132 first found in 1999")
rec, best = [], 0                                 # road one: record gaps to 10^8
for a, b in zip(primes, primes[1:]):
    if b - a > best: best = b - a; rec.append((b - a, a))
print(f"record gaps below 10^8 ({len(rec)}), gap@prime:")
for k in range(0, len(rec), 7):
    print("  " + ", ".join(f"{d}@{a:,}" for d, a in rec[k:k + 7]))
known = [1, 2, 4, 6, 8, 14, 18, 20, 22, 34, 36, 44, 52, 72, 86, 96, 112, 114, 118, 132, 148, 154, 180, 210, 220]
mr_ok = all(is_prime(a) and is_prime(a + d) and not any(is_prime(n) for n in range(a + 1, a + d)) for d, a in rec)
yn = lambda b: "yes" if b else "no"
print(f"records match the quoted table: {yn([d for d, a in rec] == known)}; every endpoint and gap confirmed by Miller-Rabin: {yn(mr_ok)}")
quoted = {9: 282, 10: 354, 11: 464, 12: 540, 13: 674, 14: 804, 15: 906, 16: 1132}
Gx = {}
print("x | G(x) | (log x)^2 | G / (log x)^2 | model log x (log x - log log x)")
for e in range(2, 17):
    x = 10**e
    G = quoted[e] if e > 8 else max(d for d, a in rec if a + d <= x)
    Gx[e] = G; lx = math.log(x)
    print(f"10^{e} | {G:,}{' (quoted)' if e > 8 else ''} | {lx*lx:.1f} | {G/(lx*lx):.3f} | {lx*(lx-math.log(lx)):.1f}")
n8 = len(primes)
print(f"pi(10^8) = {n8:,}; average gap (p_last - 2) / (count - 1) = {(primes[-1]-2)/(n8-1):.3f}; log 10^8 = {math.log(N):.3f}; largest gap {rec[-1][0]}")
tail = [0] * 6                                    # share of gaps above t log p
for a, b in zip(primes[1:], primes[2:]):
    r = (b - a) / math.log(a)
    for t in range(1, 6):
        if r > t: tail[t] += 1
m = n8 - 2
print("t | share of gaps after p above t log p, p < 10^8 | model e^-t")
for t in range(1, 6):
    print(f"{t} | {tail[t]/m:.5f} | {math.exp(-t):.5f}")
M64 = (1 << 64) - 1
def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state; z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, z ^ (z >> 31)
X = 10**6
inv = [0.0, 0.0, 0.0] + [1 / math.log(n) for n in range(3, X + 1)]
runs = []
for seed in range(1, 21):                         # road three: the coin-flip model
    st, last, mx, cnt = seed, 2, 0, 1
    for n in range(3, X + 1):
        st, z = splitmix(st)
        if (z >> 11) / 9007199254740992 < inv[n]:
            mx = max(mx, n - last); last = n; cnt += 1
    runs.append((mx, cnt))
mxs = [r[0] for r in runs]; mean_cnt = sum(r[1] for r in runs) / 20
expect = 1 + add(inv)
print(f"model to 10^6, 20 runs (SplitMix64, seeds 1-20): largest gaps {', '.join(map(str, mxs))}")
print(f"  mean largest gap {sum(mxs)/20:.1f}; runs above the true 114: {sum(1 for v in mxs if v > 114)}; mean count {mean_cnt:,.1f};"
      f" expected 1 + sum 1/log n = {expect:,.1f}; true pi(10^6) = {primes.index(999983)+1:,}")
twins = sum(1 for a, b in zip(primes, primes[1:]) if b - a == 2 and b <= X)
cram = add(1 / (math.log(n) * math.log(n + 2)) for n in range(3, X - 1))
u0, u1 = math.log(2), math.log(X)                 # Simpson in u = log t: dt / log^2 t = e^u du / u^2
h = (u1 - u0) / X; simp = math.exp(u0) / u0**2 + math.exp(u1) / u1**2
for i in range(1, X): simp += (4 if i % 2 else 2) * math.exp(u0 + i * h) / (u0 + i * h)**2
simp *= h / 3
C2 = math.prod(1 - 1 / (p - 1)**2 for p in primes[1:primes.index(999983) + 1])
print(f"twin pairs below 10^6: true {twins:,}; Cramer model: integral of 1/log^2 t = {simp:,.1f}, sum 1/(log n log(n+2)) = {cram:,.1f}")
print(f"twin constant C2 = {C2:.6f}; Hardy-Littlewood 2 C2 x integral = {2*C2*simp:,.1f}")
l2, l3 = math.log(L), math.log(math.log(L)); l4 = math.log(l3)
lf = add(math.log10(k) for k in range(2, g + 1))
lp = add(math.log10(q) for q in primes if q <= 1129)
print(f"at p: log log p = {l2:.3f}; 2018 lower-bound shape (log p)(log2 p)(log4 p) / (log3 p) = {L*l2*l4/l3:.1f}; x^0.525 = {sci(math.exp(0.525*L))};"
      f" sqrt(p) log p = {sci(math.sqrt(P)*L)}")
print(f"factorial road: gap of {g:,} needs {g:,}! = 10^{lf:.1f}; primorial road: 1129# = 10^{lp:.1f}")
kb = 1024 * math.log(2)
print(f"1024-bit primes: log 2^1024 = {kb:.2f}; odd numbers tested on average about {kb/2:.1f}; (log 2^1024)^2 = {kb*kb:,.0f}")
chart = [Gx[e] for e in range(2, 17)]
print("chart G(x):", ", ".join(str(v) for v in chart))
print("chart (log x)^2:", ", ".join(f"{math.log(10**e)**2:.0f}" for e in range(2, 17)))
print("chart model:", ", ".join(f"{math.log(10**e)*(math.log(10**e)-math.log(math.log(10**e))):.0f}" for e in range(2, 17)))
assert mr == sv == [P, P + g]                     # two roads agree on the example
assert [d for d, a in rec] == known and mr_ok and rec[-1] == (220, 47326693)
assert n8 == 5761455 and twins == 8169 and round(simp) == 6247 and round(2 * C2 * simp) == 8248            # known tables
assert all(Gx[e] < math.log(10**e)**2 for e in range(2, 9)) and abs(cram - simp) < 0.001 * simp
assert abs(mean_cnt - expect) < 3 * math.sqrt(expect) / math.sqrt(20)
assert all(abs(tail[t] / m - math.exp(-t)) < 0.6 * math.exp(-t) for t in range(1, 4))
assert 0.8 < (primes[-1] - 2) / (n8 - 1) / math.log(N) < 1.0 and abs(gstar - g) < 0.05 * g
print("ALL CHECKS PASS")
