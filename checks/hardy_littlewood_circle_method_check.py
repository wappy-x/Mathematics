# The circle method for five squares -- the check behind the card.  Standard library only.
# Road 1 counts r_5(n) directly.  Road 2 is the circle integral, done exactly with 5,000
# sample points, then split into major and minor arcs.  Road 3 is the prediction: the
# singular series from Gauss sums, times the singular integral.  Road 4 rebuilds the
# series from local solution counts mod p^k.  math.gamma appears only as a cross-check.
import math

def reps(s, N):                      # r_s(m) for m <= N: signs and order counted
    sq = [0] * (N + 1)
    for x in range(-math.isqrt(N), math.isqrt(N) + 1): sq[x * x] += 1
    r = [1] + [0] * N
    for _ in range(s):
        r = [sum(r[m - k] * sq[k] for k in range(m + 1) if sq[k]) for m in range(N + 1)]
    return r

r5, r3, r4 = reps(5, 1001), reps(3, 1007), reps(4, 1024)
print(f"count, r_5(1000) = {r5[1000]:,}, r_5(1001) = {r5[1001]:,}")

# ---- road 2: the circle integral, sampled at alpha = j/M ----
M, P = 5000, 31                      # 5 x 31^2 = 4,805 < 5,000, so the samples are exact
C = [math.cos(2 * math.pi * k / M) for k in range(M)]
S_ = [math.sin(2 * math.pi * k / M) for k in range(M)]
f = []
for j in range(M):
    ks = [(j * x * x) % M for x in range(-P, P + 1)]
    f.append(complex(sum(C[k] for k in ks), sum(S_[k] for k in ks)))
def piece(js, n): return sum((f[j] ** 5 * complex(C[-j * n % M], S_[-j * n % M])).real for j in js) / M
I1000, I1001 = piece(range(M), 1000), piece(range(M), 1001)
print(f"integral, n = 1000: {I1000:,.1f}; n = 1001: {I1001:,.1f}")
assert round(I1000) == r5[1000] and round(I1001) == r5[1001]

def arcs(Q, W):                      # sample points within W/(qM) = 1/(200q) of a/q, for q <= Q
    return {j for q in range(1, Q + 1) for a in range(q + 1) if math.gcd(a, q) == 1
            for j in range(M) if abs(j * q - a * M) <= W}
c = [1] + [0] * (5 * P * P)          # c[m]: ways to make m from five squares of -31..31, every m to 4,805
for _ in range(5): c = [sum(c[m - x * x] * (2 if x else 1) for x in range(min(P, math.isqrt(m)) + 1)) for m in range(len(c))]
def arc(q, n, w):                    # exact integral of f^5 e(-n alpha) = sum c[m] e((m-n) alpha) over the arcs
    return sum(cm * (2 * w if m == n else math.cos(2 * math.pi * (m - n) * a / q) * math.sin(2 * math.pi * (m - n) * w)
                     / (math.pi * (m - n))) for a in range(q) if math.gcd(a, q) == 1 for m, cm in enumerate(c) if cm)
assert c[1000] == r5[1000] and abs(sum(arc(d, 1000, 1 / 20) for d in (1, 2, 5, 10)) - r5[1000]) < 1e-6  # arcs round each a/10 tile the circle
for Q in (10, 5):
    mj = arcs(Q, 25); mn = [j for j in range(M) if j not in mj]; maj = sum(arc(q, 1000, 25 / (q * M)) for q in range(1, Q + 1))
    sh = sum(2 * 25 / (q * M) for q in range(1, Q + 1) for a in range(q) if math.gcd(a, q) == 1)
    print(f"arcs q <= {Q}, integrated exactly: share of circle {sh:.4f}, of count {maj / r5[1000]:.4f}; major {maj:,.1f}, "
          f"minor {r5[1000] - maj:,.1f}; largest |f| at the minor-arc samples {max(abs(f[j]) for j in mn):.2f}")
    if Q == 10: minor = mn
print(f"|f| at 0, 1/4, 1/5, 1/2: {abs(f[0]):.2f}, {abs(f[1250]):.2f}, {abs(f[1000]):.2f}, {abs(f[2500]):.2f}; "
      f"root mean square {math.sqrt(sum(abs(z) ** 2 for z in f) / M):.2f}")
mean4 = sum(abs(z) ** 4 for z in f) / M
print(f"mean of |f|^4 = {mean4:,.1f}; minor-arc bound max|f| x mean|f|^4 at least "
      f"{max(abs(f[j]) for j in minor) * mean4:,.0f}, from the sampled max")

# ---- Weyl's inequality: |f|^2 <= sum over |h| <= 2P of min(2P+1, 1/(2||2h alpha||)) ----
def weyl(j):
    t = 0.0
    for h in range(-2 * P, 2 * P + 1):
        d = (2 * h * j) % M; d = min(d, M - d) / M
        t += 2 * P + 1 if d == 0 else min(2 * P + 1, 1 / (2 * d))
    return t
wr = max(abs(f[j]) ** 2 / weyl(j) for j in minor)
print(f"Weyl at the minor-arc samples: worst |f|^2 / bound = {wr:.4f}, bound on |f| <= {math.sqrt(max(weyl(j) for j in minor)):.2f}")
assert wr <= 1

# ---- road 3: singular series from Gauss sums, singular integral from the ball ----
def e(x): return complex(math.cos(2 * math.pi * x), math.sin(2 * math.pi * x))
def A(q, n, s=5):
    return sum(sum(e(a * x * x / q) for x in range(q)) ** s * e(-a * n / q)
               for a in range(1, q + 1) if math.gcd(a, q) == 1).real / q ** s
G52 = 3 * math.sqrt(math.pi) / 4     # Gamma(5/2) = (3/2)(1/2)Gamma(1/2)
h = 60 / 60000                       # Simpson's rule for the integral of t^(3/2) e^(-t) on [0, 60]
simp = sum((1 if k in (0, 60000) else 4 if k % 2 else 2) * (k * h) ** 1.5 * math.exp(-k * h)
           for k in range(60001)) * h / 3
print(f"Gamma(5/2) = {G52:.8f}; by Simpson's rule {simp:.8f}")
assert abs(simp - G52) < 1e-6 and abs(math.gamma(2.5) - G52) < 1e-12   # math.gamma: cross-check only
def J(n, s=5, g=G52): return math.pi ** (s / 2) * n ** (s / 2 - 1) / g
print(f"J(1000) = (4 pi^2 / 3) x 1000^(3/2) = {4 * math.pi ** 2 / 3:.4f} x {1000 ** 1.5:,.2f}")
ball = 8 * math.pi ** 2 / 15 * 1000 ** 2.5
print(f"lattice points in the ball of radius sqrt(1000): {sum(r5[:1001]):,}; volume {ball:,.0f}")
series = {}
for n in (1000, 1001):
    part, cut = 0.0, {}
    for q in range(1, 121):
        part += A(q, n); cut[q] = part
    series[n] = cut
    print(f"n = {n}: J = {J(n):,.1f}, series to 120 = {part:.4f}, prediction {part * J(n):,.1f}, "
          f"off by {100 * (part * J(n) / r5[n] - 1):.3f}%")
pts = (1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 30, 40, 60, 80, 100, 120)
print("chart, prediction with series cut at q:", ", ".join(f"{series[1000][q] * J(1000):.0f}" for q in pts))
assert abs(series[1000][120] * J(1000) / r5[1000] - 1) < 0.002

# ---- road 4: local factors, by counting solutions mod p^k and by Gauss sums ----
def density(p, k, n, s=5):
    m = p ** k; c = [0] * m
    for x in range(m): c[x * x % m] += 1
    cur = c
    for _ in range(s - 1):
        nw = [0] * m
        for i in range(m):
            if cur[i]:
                for t in range(m):
                    if c[t]: nw[(i + t) % m] += cur[i] * c[t]
        cur = nw
    return cur[n % m] / m ** (s - 1)
local = {}
for n, ps in ((1000, ((2, 6), (3, 2), (5, 4), (7, 2))), (1001, ((2, 6), (7, 2), (11, 2), (13, 2)))):
    for p, k in ps:
        g = 1 + sum(A(p ** i, n) for i in range(1, k + 1))
        local[n, p] = density(p, k, n)
        print(f"local factor n = {n}, p = {p}: count {local[n, p]:.7f}, Gauss sums {g:.7f}")
        assert abs(g - local[n, p]) < 1e-9
sieve = bytearray([1]) * 200001; sieve[:2] = b"\0\0"
for i in range(2, 448):
    if sieve[i]: sieve[i * i::i] = bytearray(len(sieve[i * i::i]))
for n in (1000, 1001):
    prod = 1.0
    for p in range(2, 200001):
        if sieve[p]:
            leg = pow(n, (p - 1) // 2, p)
            prod *= local[n, p] if (n, p) in local else 1 + (1 if leg == 1 else -1) / p ** 2
    print(f"full product to 200,000, n = {n}: series {prod:.7f}, times J = {prod * J(n):,.1f}")
    assert abs(prod * J(n) - r5[n]) < 1

# ---- what breaks ----
print(f"drop the series: J = {J(1000):,.1f} against {r5[1000]:,}, {100 * (J(1000) / r5[1000] - 1):.1f}% high")
print(f"three squares at 1007: J = {J(1007, 3, math.sqrt(math.pi) / 2):,.1f}, r_3 = {r3[1007]}, "
      f"2-adic factor {density(2, 5, 1007, 3):.4f}")
print(f"four squares at 1024: J = {J(1024, 4, 1.0):,.1f}, r_4 = {r4[1024]}, r_4 / J {r4[1024] / J(1024, 4, 1.0):.4f}; "
      f"r_4(1000) = {r4[1000]:,}")
assert r3[1007] == 0 and density(2, 5, 1007, 3) == 0 and r4[1024] == 24
print("ALL CHECKS PASS")
