# Roth's theorem on three-term progressions -- the check behind the card.
# Standard library only.  Road one finds r3(N), the largest progression-free
# set in 1..N, by trying every subset and by a pruned exhaustive search.  Road
# two counts progressions of A = {1, 2, 4, 8, 9} modulo M = 19 directly and by
# the Fourier sum.  Then it runs the density-increment step on A and on the
# base-3 set in 1..729, and the iteration that gives 72 N / log log N.
import math

def e(t):                                         # the arrow e(t), a turn t round the circle
    return complex(math.cos(2 * math.pi * t), math.sin(2 * math.pi * t))

def fx(v):                                        # six decimals, never "-0.000000"
    s = f"{v:.6f}"
    return "0.000000" if s == "-0.000000" else s

def has3(S):                                      # does S hold x, y, z with x + z = 2y, x < z?
    T = set(S)
    return any((x + z) % 2 == 0 and (x + z) // 2 in T for x in S for z in S if x < z)

def r3_dfs(n):                                    # pruned exhaustive search: size, all best sets
    best = [0, []]
    def go(pos, ch):
        if len(ch) + n - pos + 1 < best[0]: return
        if pos > n:
            if len(ch) > best[0]: best[:] = [len(ch), []]
            best[1].append(sorted(ch)); return
        if all(2 * y - pos not in ch for y in ch):
            ch.add(pos); go(pos + 1, ch); ch.discard(pos)
        go(pos + 1, ch)
    go(1, set())
    return best

brute = [max(bin(m).count("1") for m in range(2**n)
             if not has3([i + 1 for i in range(n) if m >> i & 1])) for n in range(1, 13)]
R = [r3_dfs(n) for n in range(1, 21)]
r3 = [r[0] for r in R]
print("r3(N) by trying every subset, N = 1..12:", brute)
print("r3(N) by pruned exhaustive search, N = 1..20:", r3)
print("largest progression-free sets in 1..9:", R[8][1])
print(f"largest in 1..20: size {r3[19]}, {len(R[19][1])} such sets, first {R[19][1][0]}")
print("chart, share r3(N)/N:", ", ".join(f"{r3[n - 1] / n:.3f}" for n in range(1, 21)))
assert brute == r3[:12] and r3[8] == 5 and r3[19] == 9 and [1, 2, 4, 8, 9] in R[8][1]
b9 = [[i + 1 for i in range(9) if m >> i & 1] for m in range(2**9) if bin(m).count("1") == 5]
b9 = sorted(S for S in b9 if not has3(S))         # the largest sets in 1..9 again, by trying every subset
assert b9 == sorted(R[8][1]) and len(b9) == 4 and len(R[19][1]) == 2

A, N = [1, 2, 4, 8, 9], 9
M, dens = 2 * N + 1, len(A) / N
ind = [1 if x in A else 0 for x in range(M)]       # A as a set of residues mod M
def hat(g, xi):                                   # hat g(xi) = (1/M) sum g(x) e(-x xi / M)
    return sum(g[x] * e(-(x * xi % M) / M) for x in range(M)) / M
def T(g1, g2, g3, m=M):                           # weighted count of x, x + d, x + 2d mod m
    return sum(g1[x] * g2[(x + d) % m] * g3[(x + 2 * d) % m] for x in range(m) for d in range(m))
H = [hat(ind, xi) for xi in range(M)]
terms = [M * M * H[xi] ** 2 * H[-2 * xi % M] for xi in range(M)]
direct = T(ind, ind, ind)
print(f"A = {A}, N = {N}, modulus M = {M}, density in 1..{N} = {dens:.6f}")
print(f"pairs (x, d) mod {M} with x, x+d, x+2d in A, counted directly: {direct}")
print(f"the same by the Fourier sum: {sum(terms).real:.6f}; xi = 0 term {terms[0].real:.6f}; "
      f"other {M - 1} terms {sum(terms[1:]).real:.6f}")
print("sizes |hat A(xi)|, xi = 0..9:", ", ".join(f"{abs(h):.4f}" for h in H[:10]))
print(f"Parseval: sum of |hat A|^2 = {sum(abs(h) ** 2 for h in H):.6f}, |A|/M = {len(A) / M:.6f}")
hmax = max(abs(h) for h in H[1:]); cap = M * hmax * len(A)   # M^2 x largest x |A|/M
print(f"largest |hat A(xi)| with xi != 0: {hmax:.4f}; Parseval caps the other terms at {cap:.6f}")
assert direct == len(A) and abs(sum(terms) - direct) < 1e-9 and abs(sum(terms[1:])) <= cap
assert abs(sum(abs(h) ** 2 for h in H) - len(A) / M) < 1e-12

TP = sum(1 for x in range(1, N + 1) for y in range(1, N + 1) for z in range(1, N + 1) if x + z == 2 * y)
P = [1 if 1 <= x <= N else 0 for x in range(M)]
f = [ind[x] - dens * P[x] for x in range(M)]      # the balanced function, zero sum
dP = [dens * p for p in P]
corr = [abs(sum(f[x] * e(-(x * xi % M) / M) for x in range(M))) for xi in range(M)]
big = max(range(1, (M + 1) // 2), key=lambda xi: corr[xi])
c3 = [T(f, ind, ind).real, T(dP, f, ind).real, T(dP, dP, f).real]
promise = (dens**2 * TP / N - 1) / 3
print(f"integer solutions of x + z = 2y in 1..{N}: T(P) = {TP} (formula {(N + 1) // 2}^2 + {N // 2}^2); "
      f"density^3 T(P) = {dens**3 * TP:.6f}")
print("three correction terms:", ", ".join(fx(c) for c in c3), f"; sum {sum(c3):.6f}")
print(f"largest |sum f(x) e(-x xi/{M})|: {corr[big]:.6f} at xi = {big}; the proof promises at least {promise:.6f}")
assert TP == ((N + 1) // 2) ** 2 + (N // 2) ** 2 and abs(sum(c3) - (direct - dens**3 * TP)) < 1e-9
assert all(abs(c) <= dens * N * corr[big] + 1e-9 for c in c3) and corr[big] >= promise > 0

xi, Q = 9, math.isqrt(N)                          # the step: wave xi, Dirichlet with q <= sqrt N
def dist(q): r = q * xi % M; return min(r, M - r) / M
q = next(q for q in range(1, Q + 1) if dist(q) <= 1 / (Q + 1))
print(f"wave xi = {xi}: correlation {corr[xi]:.6f}; Dirichlet gives q = {q}, ||q theta|| = {dist(q):.6f}")
pieces = [list(range(a, N + 1, q)) for a in range(1, q + 1)]
for Pc in pieces:
    k = sum(1 for x in Pc if x in A)
    print(f"piece {Pc}: {k} of {len(Pc)} in A, density {k / len(Pc):.6f}, surplus {k - dens * len(Pc):.6f}")
top = max(pieces, key=lambda Pc: sum(1 for x in Pc if x in A) / len(Pc))
new = [(x - top[0]) // q + 1 for x in top if x in A]
print(f"rescaled: {new} inside 1..{len(top)}, density {len(new) / len(top):.6f}, progression-free: "
      f"{'no' if has3(new) else 'yes'}")
assert not has3(new) and len(new) / len(top) - dens >= corr[xi] / N / 4

N3 = 729; M3 = 2 * N3 + 1                           # the base-3 set: digits 0 and 1, plus one
B = [m + 1 for m in range(N3) if all(m // 3**j % 3 < 2 for j in range(6))]
d3 = len(B) / N3; inB = set(B)
f3 = [(1 if x in inB else 0) - d3 for x in range(N3 + 1)]
c3x = [abs(sum(f3[x] * e(-(x * k % M3) / M3) for x in range(1, N3 + 1))) for k in range(1, N3 + 1)]
k3 = max(range(N3), key=lambda k: c3x[k]) + 1
thirds = [sum(1 for x in B if 243 * j < x <= 243 * (j + 1)) for j in range(3)]
print(f"base-3 set in 1..{N3}: {len(B)} members, density {d3:.6f}, progression-free: {'no' if has3(B) else 'yes'}")
print(f"  promise {d3**2 * N3 / 12:.6f} (N >= 4/density^2 = {4 / d3**2:.1f}); largest {c3x[k3 - 1]:.6f} at xi = {k3}")
print(f"  thirds of 1..{N3}: {thirds} members, densities", ", ".join(f"{t / 243:.6f}" for t in thirds))
assert not has3(B) and c3x[k3 - 1] >= d3**2 * N3 / 12 and N3 >= 4 / d3**2 and max(thirds) / 243 > d3

def steps(d0):                                    # density steps u -> u + u^2/48 until above 1
    u, k = d0, 0
    while u <= 1: u += u * u / 48; k += 1
    return k
def threshold(d0):                                # log log N above this forbids density d0
    return (steps(d0) - 1) * math.log(2) + math.log(4 * math.log(96 * math.pi / d0**2))
print("density | steps K | log log N must stay below | 72/density | digits of N, about 10^")
for d0 in (0.5, 0.1, 0.01):
    t = threshold(d0)
    print(f"{d0} | {steps(d0)} | {t:.3f} | {72 / d0:.1f} | {t / math.log(10) - math.log10(math.log(10)):.1f}")
worst = max(threshold(j / 100) * j / 100 for j in range(1, 101))
print(f"largest density x threshold over density 0.01..1.00: {worst:.3f} (the card's constant is 72)")
a96 = math.log(96 * math.pi); b96 = math.log(4 * a96)     # the fold's constants
print(f"constant: log(96 pi) = {a96:.3f}, 4 x that = {4 * a96:.2f}, its log = {b96:.3f}, "
      f"98 log 2 = {98 * math.log(2):.2f}, sum {98 * math.log(2) + b96:.2f}")
assert all(steps(j / 100) - 1 <= 98 * 100 / j for j in range(1, 101)) and worst < 72
assert 98 * math.log(2) + b96 < 72

W = [1 if x in [a % N for a in A] else 0 for x in range(N)]  # A read modulo 9: 9 becomes 0
wrap = T(W, W, W, m=N)
print(f"mistake, modulus {N} instead of {M}: {wrap} pairs, not {direct}; 8, 9, 10 wraps to 8, 0, 1")
print(f"mistake, largest |hat A| of A itself: {abs(H[0]):.4f} at xi = 0, which is |A|/M = {len(A) / M:.4f}")
print(f"mistake, the bound at N = 10^6: 72 / log log N = {72 / math.log(math.log(10**6)):.2f}, above 1")
assert wrap == 13 and wrap > direct
print("ALL CHECKS PASS")
