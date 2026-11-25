# Weyl differencing and van der Corput -- the check behind the card.  Standard library only.
# e(x) = cos 2 pi x + i sin 2 pi x; ||x|| = distance from x to the nearest whole number.
# Roads: S(N) = sum of e(root2 n^2) added term by term, against |S|^2 rebuilt from the squared
# sum's linear inner sums in closed form; van der Corput's inequality and Weyl's bound against
# both; the second-derivative test against a directly added sum of n^(-it).
from math import isqrt, cos, sin, pi, sqrt, log, tan

ONE = 1 << 32
def fr2(m):            # {m root2} for a whole number m >= 0, exact to 2^-32, by integer square root
    return (isqrt(2 * m * m * ONE * ONE) % ONE) / ONE
def e(x): return complex(cos(2 * pi * x), sin(2 * pi * x))
def nrm(x): return min(x, 1 - x)              # ||x|| for x in [0, 1)
def lin(m, L):         # sum_{n=1}^{L} e(root2 m n), a geometric series in closed form
    if L == 0: return 0j
    r = e(fr2(m)); return r * (e(fr2(m * L)) - 1) / (r - 1)

N = 10000
z = [e(fr2(n * n)) for n in range(N + 1)]       # z[n] = e(root2 n^2); z[0] unused
S, run, chart = 0j, {}, []
for n in range(1, N + 1):
    S += z[n]; run[n] = abs(S)
    if n % 500 == 0: chart.append(n)
print("root2 = 1.41421356; S(N) = sum_{n<=N} e(root2 n^2)")
# road 2: |S|^2 = N + 2 Re sum_h r(h), r(h) = sum_n z[n+h] conj(z[n]) = e(root2 h^2) lin(2h, N-h)
def r(h, M): return e(fr2(h * h)) * lin(2 * h, M - h)
for M in (1000, N):
    sq = M + 2 * sum(r(h, M).real for h in range(1, M))
    print(f"N = {M:5d}: |S| added term by term {run[M]:.2f}; from the squared sum {sqrt(sq):.2f}; "
          f"root N {sqrt(M):.2f}; |S|/N {run[M] / M:.6f}")
    assert abs(sq - run[M] ** 2) < 1e-6 * M
for h in range(1, 21):                           # closed-form r(h) against the pairs added directly
    d = sum(z[n + h] * z[n].conjugate() for n in range(1, N - h + 1))
    assert abs(d - r(h, N)) < 1e-5
print("r(h) closed form = r(h) added directly, h = 1..20: yes")
print("chart N:", ", ".join(str(n) for n in chart))
print("chart |S|:", ", ".join(f"{run[n]:.1f}" for n in chart))
print("chart root N:", ", ".join(f"{sqrt(n):.1f}" for n in chart))
print(f"largest |S(N)| for N <= {N}: {max(run.values()):.2f}")
rs = [0j] + [r(h, N) for h in range(1, N)]
assert all(abs(rs[h]) <= min(N - h, 1 / (2 * nrm(fr2(2 * h)))) + 1e-9 for h in range(1, N))
HS = (1, 6, 35, 204, 1189)
print("inner caps 1/(2||2h root2||), h = 1, 6, 35, 204, 1189:", ", ".join(f"{1 / (2 * nrm(fr2(2 * h))):.3f}" for h in HS))
print("  2h root2 is nearest", ", ".join(str(round(2 * h * 1.4142135623730951)) for h in HS))
print("inner sizes |r(h)|, same h:", ", ".join(f"{abs(rs[h]):.3f}" for h in HS))
print(f"without the diagonal h = 0: 2 Re sum r(h) = {2 * sum(x.real for x in rs):.1f}")
# van der Corput's inequality: |S|^2 <= (N+H-1)/H * sum_{|h|<H} (1 - |h|/H) r(h)
print(f"van der Corput, N = {N}, |S|^2 = {run[N] ** 2:.1f}:")
for H in (1, 10, 100, 1000, N):
    w = (N + H - 1) / H
    ex = w * (N + 2 * sum((1 - h / H) * rs[h].real for h in range(1, H)))
    ab = w * (N + 2 * sum((1 - h / H) * abs(rs[h]) for h in range(1, H)))
    print(f"  H = {H:5d}: right side {ex:.1f} (root {sqrt(ex):.2f}); with |r(h)| {ab:.1f} (root {sqrt(ab):.2f})")
    assert run[N] ** 2 <= ex + 1e-6 and ex <= ab + 1e-6
# Weyl: |r(h)| <= min(N-h, 1/(2||2 h root2||)), so |S|^2 <= B; then a fraction p/q near root2 bounds B
def pell(Q):           # largest denominator q <= Q of a fraction p/q with p^2 - 2 q^2 = +-1
    p, q = 1, 1
    while p + q <= Q: p, q = p + 2 * q, p + q
    return p, q
for M in (1000, N):
    B = M + 2 * sum(min(M - h, 1 / (2 * nrm(fr2(2 * h)))) for h in range(1, M))
    Lsum = sum(min(M, 1 / (2 * nrm(fr2(h)))) for h in range(1, 2 * M - 1))
    p, q = pell(M)
    assert abs(p * p - 2 * q * q) == 1
    W = M + 2 * (2 * M / q + 1) * (4 * M + q * (1 + log(q)))
    print(f"Weyl, N = {M:5d}: sum of mins B = {B:.1f}, root {sqrt(B):.2f}; fraction {p}/{q}; "
          f"block bound {W:.1f}, root {sqrt(W):.2f}")
    assert run[M] ** 2 <= B and B - M <= 2 * Lsum + 1e-6 and 2 * Lsum <= W - M
    blks = [sorted((min(M, 1 / (2 * nrm(fr2(h)))) for h in range(h0, min(h0 + q, 2 * M - 1))), reverse=True)
            for h0 in range(1, 2 * M - 1, q)]  # the fold's lemma, one block of q shifts at a time
    tight = max(t * 2 * (i // 2 + 1) / q for b in blks for i, t in enumerate(b[4:]))
    print(f"  {len(blks)} blocks of {q} shifts: largest block sum {max(sum(b) for b in blks):.1f} <= 4N + q(1 + log q) = "
          f"{4 * M + q * (1 + log(q)):.1f}; after each block's top four, worst term / cap q/2, q/2, q/4, ... = {tight:.4f}")
    assert all(sum(b) <= 4 * M + q * (1 + log(q)) for b in blks) and tight < 1
# a rational step: alpha = 1393/985 is within 1/(985^2) of root2, yet its sum grows like N
G = abs(sum(e((1393 * n * n % 985) / 985) for n in range(1, 986)))
T = [0j]
for n in range(1, N + 1): T.append(T[-1] + e((1393 * n * n % 985) / 985))
print(f"1393/985: one period |G| = {G:.4f}, root 985 = {sqrt(985):.4f}; |S(9850)| = {abs(T[9850]):.2f} "
      f"= 10 root 985; |S(1000)| = {abs(T[1000]):.2f}; |S(10000)| = {abs(T[N]):.2f}")
assert abs(G - sqrt(985)) < 1e-9 and abs(abs(T[9850]) - 10 * sqrt(985)) < 1e-7
# equidistribution of {root2 n^2}: ten bins, and Weyl averages at spins m = 1, 2, 3
bins = [0] * 10
for n in range(1, N + 1): bins[int(10 * fr2(n * n))] += 1
avg = [abs(sum(e(fr2(m * n * n)) for n in range(1, N + 1))) / N for m in (1, 2, 3)]
print("{root2 n^2}, n <= 10000, ten bins:", " ".join(str(b) for b in bins))
print("Weyl averages, spins 1, 2, 3:", ", ".join(f"{a:.6f}" for a in avg))
assert sum(bins) == N and max(abs(b - N // 10) for b in bins) < 60 and max(avg) < 0.03
c3 = abs(sum(e(fr2(n ** 3)) for n in range(1, 1001)))
print(f"cubes: |sum_{{n<=1000}} e(root2 n^3)| = {c3:.2f}")
# van der Corput's second-derivative test on sum_{M<n<=2M} n^(-it) = sum e(f(n)), f(x) = -t ln x/(2 pi)
t, M = 100000.0, 10000
f = lambda x: -t * log(x) / (2 * pi)
Z = abs(sum(e(f(n)) for n in range(M + 1, 2 * M + 1)))
lam, rho = t / (2 * pi * (2 * M) ** 2), 4.0                # lam <= f'' <= rho lam on [M, 2M]
K = rho * lam * M + 2
bnd = K * (2 / sqrt(lam) + 1) + (K + 1) * (2 / (pi * sqrt(lam)) + 1)
print(f"t = {t:.0f}, M = {M}: |sum n^(-it)| = {Z:.2f}; second-derivative bound {bnd:.1f}; "
      f"trivial {M}; stationary-phase size root(t/(2 pi)) = {sqrt(t / (2 * pi)):.2f}")
print(f"  lambda = {lam:.10f}, root lambda = {sqrt(lam):.6f}, rho lambda M = {rho * lam * M:.4f}")
assert Z <= bnd < M and abs(Z - sqrt(t / (2 * pi))) < 0.05 * Z
# Kusmin-Landau: f'(x) = -t/(2 pi x) stays in the safe range -1.9..-1.1 for n0 <= n <= n1
n0, n1, cap = int(t / (2 * pi * 1.9)) + 1, int(t / (2 * pi * 1.1)), 1 / tan(pi * 0.1 / 2) + 1
fp = lambda x: -t / (2 * pi * x)
for a in (M + 1, n0):                                       # a piece inside the safe range, then all of it
    KL = abs(sum(e(f(n)) for n in range(a, n1 + 1)))
    print(f"Kusmin-Landau, n = {a}..{n1}, f' from {fp(a):.5f} to {fp(n1):.5f}, delta = 0.1: |sum| = {KL:.4f}, "
          f"bound cot(pi delta/2) + 1 = {cap:.4f}")
    assert -1.9 <= fp(a) and fp(n1) <= -1.1 and KL <= cap
L2 = 2 * sqrt(2)                                           # f'' for root2 x^2
K2 = L2 * N + 2
blind = K2 * (2 / sqrt(L2) + 1) + (K2 + 1) * (2 / (pi * sqrt(L2)) + 1)
print(f"second-derivative bound applied to root2 n^2 (f'' = {L2:.4f} > 1/4), N = {N}: {blind:.0f} > N")
assert blind > N
print("ALL CHECKS PASS")
